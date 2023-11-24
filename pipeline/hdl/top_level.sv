`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  input wire [3:0] btn,
  output logic [15:0] led,
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1 //rgb led
);
  localparam STORE_PERIOD = 2; // number of clock cycles for a memory write
  localparam LOAD_PERIOD = 2; // number of clock cycles for a memory read

  // assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];

  logic correct_branch;
  logic ready_decode;
  logic ready_exe;
  logic ready_mem;

  logic[1:0] store_counter;
  logic[1:0] load_counter;
  logic exe_complete;
  assign correct_branch = (iType_exe != BRANCH && iType_exe != JAL && iType_exe != JALR) || nextPc == (pc_exe + 4);
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      //Simulates instruction fetch
      inst <= inst_fetched;
      pc <= 32'h0000_0000;
      store_counter <= 0;
      load_counter <= 0;
    end else begin
      // IF
      if (ready_decode) begin
        if (end_of_file === 1'bx) begin
          pc <= (correct_branch || nextPc === 32'bx) ? pc + 4 : nextPc;
        end else begin
          pc <= (end_of_file) ? pc : (correct_branch || nextPc === 32'bx) ? pc + 4 : nextPc;
        end
        // IF -> ID
        inst <= (correct_branch) ? inst_fetched : 0;
        pc_decode <= pc;
      end
      // ID -> EXE
      if (ready_decode) begin
        iType_exe <= (correct_branch) ? iType : NOP;
        aluFunc_exe <= (correct_branch) ? aluFunc : NoAlu;
        brFunc_exe <= (correct_branch) ? brFunc : Dbr;
        imm_exe <= imm;
        rd_exe <= rd;
        pc_exe <= pc_decode;
        rval1_exe <= rval1;
        rval2_exe <= rval2;
      end else if (ready_exe) begin
        iType_exe <= NOP;
        aluFunc_exe <= NoAlu;
        brFunc_exe <= Dbr;
        imm_exe <= 0;
        rd_exe <= 0;
        pc_exe <= 0;
        rval1_exe <= 0;
        rval2_exe <= 0;
      end
      // EXE -> MEM
      if (ready_exe) begin
        rval1_mem <= rval1_exe;
        // rval1_mem <= rval1;
        imm_mem <= imm_exe;
        iType_mem <= iType_exe;
        result_mem <= result;
        rd_mem <= rd_exe;
      end else if (ready_mem) begin
        rval1_mem <= 0;
        imm_mem <= 0;
        iType_mem <= NOP;
        result_mem <= 0;
        rd_mem <= 0;
      end
      // MEM
      if (iType_mem == LOAD) begin
        if (load_counter == LOAD_PERIOD) begin
          load_counter <= 0;
        end else begin
          load_counter <= load_counter + 1;
        end
        store_counter <= 0;
      end else if (iType_mem == STORE) begin
        if (store_counter == STORE_PERIOD) begin
          store_counter <= 0;
        end else begin
          store_counter <= store_counter + 1;
        end
        load_counter <= 0;
      end else begin
        load_counter <= 0;
        store_counter <= 0;
      end
      // MEM -> WB
      if (ready_mem) begin
        iType_write <= iType_exe;
        rd_write <= rd_mem;
        mem_output_write <= mem_output;
        result_write <= result_mem;
      end else begin
        iType_write <= NOP;
        rd_write <= 0;
        mem_output_write <= mem_output;
        result_write <= result_mem;
      end
    end
  end

  always_comb begin
    // MEM is ready when the store and load are complete 
    // Using -1 because even before the data is ready, the instruction can be moved to the next stage one clock cycle early
    // So that the data is available when the instruction is in the next stage
    // TODO: Testbench this carefully
    ready_mem = iType_mem === 4'bxxxx || !((iType_mem == STORE && store_counter < STORE_PERIOD-1) || (iType_mem == LOAD && load_counter < LOAD_PERIOD-1)); 
    // EXE is ready when the calculations have finished and MEM is ready
    exe_complete = 1; //for now the execute is always complete because all logic is combinational
    ready_exe = ready_mem && exe_complete;
    // ID is ready when all its operands are ready and EXE is ready
    // TODO: Review this, it's a little suspicious
    if (ready_exe) begin
      if ((rd_mem == rs1 || rd_mem == rs2) && iType_mem == LOAD) begin
        // Load-to-stall (RAW) Hazard
        ready_decode = 1'b0;
      end else begin
        ready_decode = 1'b1;
      end
    end else begin
      ready_decode = 1'b0;
    end
    //ready_decode = ready_exe && (rs1 === 1'bx || (rd_exe != rs1 && rd_exe != rs2 && rd_mem != rs1 && rd_mem != rs2 && rd_write != rs1 && rd_write != rs2));
  end

  // instruction fetch
  logic [31:0] pc;
  logic [13:0] effective_pc;
  assign effective_pc = pc[15:2]; // different than pc for indexing into the BRAM

  logic [31:0] inst_fetched;
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(2**10),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(inst.mem))           // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_mem (
    .addra(effective_pc),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(inst_fetched)      // RAM output data, width determined from RAM_WIDTH
  );

  // decode
  logic [31:0] inst;
  logic[3:0] iType;
  logic[3:0] aluFunc;
  logic[2:0] brFunc;

  logic signed [31:0] imm;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;

  logic [31:0] pc_decode;

  decode decoder(
    .clk_in(clk_100mhz),
    .instruction_in(inst), // fill in from fetch

    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2),
    .rd_out(rd)
  );

  // Writeback Stage Register Wires
  logic signed [31:0] wd;
  logic [4:0] wa;
  logic we;
  logic signed [31:0] rd1_out, rd2_out;

  // registers (part of decode)
  register_file registers(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .rs1_in(rs1),
    .rs2_in(rs2),
    .wa_in(wa),
    .we_in(we),
    .wd_in(wd),

    .rd1_out(rd1_out), //available 1 clock cycle later
    .rd2_out(rd2_out)
  );


  logic signed [31:0] rval1;
  logic signed [31:0] rval2;
  //Bypassing 
  //TODO: Check
  always_comb begin
    if (rs1 == rd_exe) begin
      rval1 = (ready_exe) ? result : 0;
    end else if (rs1 == rd_mem) begin
      rval1 = (iType_mem != LOAD) ? result_mem : 0;
    end else if (rs1 == rd_write) begin
      rval1 = result_write;
    end else begin
      rval1 = rd1_out;
    end

    if (rs2 == rd_exe) begin
      rval2 = (ready_exe) ? result : 0;
    end else if (rs2 == rd_mem) begin
      rval2 = (iType_mem != LOAD) ? result_mem : 0;
    end else if (rs2 == rd_write) begin
      rval2 = result_write;
    end else begin
      rval2 = rd2_out;
    end
  end

  // execute
  logic signed [31:0] rval1_exe, rval2_exe;

  logic[3:0] iType_exe;
  logic[3:0] aluFunc_exe;
  logic[2:0] brFunc_exe;

  logic signed [31:0] imm_exe;
  logic [4:0] rd_exe;
  logic [31:0] pc_exe;

  logic signed [31:0] result;
  logic [31:0] addr, nextPc; 

  execute execute_module(
    .iType_in(iType_exe),
    .aluFunc_in(aluFunc_exe),
    .brFunc_in(brFunc_exe),
    .imm_in(imm_exe),
    .pc_in(pc_exe),
    .rval1_in(rval1_exe),
    .rval2_in(rval2_exe),

    .data_out(result),
    .addr_out(addr),
    .nextPc_out(nextPc)
  );

  // data memory
  logic[31:0] mem_addr;
  logic[11:0] effective_mem_addr;
  logic signed [31:0] mem_output;
  logic writing;

  logic signed [31:0] rval1_mem;
  logic signed imm_mem;
  logic [3:0] iType_mem;
  logic signed [31:0] result_mem;
  logic [4:0] rd_mem;

  assign mem_addr = rval1_mem + imm_mem;
  assign effective_mem_addr = mem_addr[8:2];
  assign writing = (iType_mem == STORE) ? 1 : 0;
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(1024),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) data_mem (
    .addra(effective_mem_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(result_mem),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(writing),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(mem_output)      // RAM output data, width determined from RAM_WIDTH
  );

  // writeback
  logic [3:0] iType_write;
  logic [4:0] rd_write;
  logic signed [31:0] mem_output_write;
  logic [31:0] previous_result;
  logic signed [31:0] result_write;
  logic [1:0] end_of_file_counter;
  logic final_result_wrote;

  logic [31:0] total_clock_cycle;

  assign wd = (iType_write == LOAD) ? mem_output_write : result_write;
  assign wa = rd_write;
  assign we = (iType_write != BRANCH) && (iType_write != STORE) && (rd_write != 0);

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      end_of_file_counter <= 0;
      end_of_file <= 0;
      final_result_wrote <= 0;
      total_clock_cycle <= 0;
    end else if (end_of_file) begin
      if (end_of_file_counter == 2 && !final_result_wrote) begin
        // final_result <= result_write;
        final_result_wrote <= 1;
        final_result <= total_clock_cycle;
      end else begin
        end_of_file_counter <= end_of_file_counter + 1;
      end
    end
  end
  logic end_of_file;
  logic signed [31:0] final_result;
  assign led = final_result;
  always_ff @(posedge clk_100mhz) begin
    if (inst_fetched === 32'b0 && pc > 0) begin
      end_of_file <= 1;
    end
  end

  always_ff @(posedge clk_100mhz) begin
    if (inst_fetched != 32'b0) begin
      total_clock_cycle <= total_clock_cycle + 1;
    end
  end

  
  // assign end_of_file = inst_fetched === 32'b0 && pc > 0;
endmodule

`default_nettype wire
