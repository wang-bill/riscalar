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
  output logic [2:0] rgb1, //rgb led
);
  assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];

  logic correct_branch;
  assign correct_branch = (iType_exe != BRANCH && iType_exe != JAL && iType_exe != JALR) || nextPc == (pc_exe + 4);
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      //Simulates instruction fetch
      inst <= inst_fetched;
      pc <= 32'h0000_0000;
    end else begin
      // IF
      pc <= (correct_branch) ? pc + 4 : nextPc;
      // IF -> ID
      inst <= (correct_branch) ? inst_fetched : 0;
      pc_decode <= pc;
      // ID -> EXE
      iType_exe <= (correct_branch) ? iType : NOP;
      aluFunc_exe <= (correct_branch) ? aluFunc : NoAlu;
      brFunc_exe <= brFunc;
      imm_exe <= imm;
      rd_exe <= rd;
      pc_exe <= pc_decode;
      // EXE -> MEM
      rval1_mem <= rval1;
      rval2_mem <= rval2;
      imm_mem <= imm_exe;
      iType_mem <= iType_exe;
      result_exe <= result;
      rd_mem <= rd_exe;
      // MEM -> WB
      iType_write <= iType_exe;
      rd_write <= rd_mem;
      mem_output_write <= mem_output;
      result_write <= result_exe;   
    end
  end

  // instruction fetch
  logic [31:0] pc;
  logic [11:0] effective_pc;
  assign effective_pc = pc[13:2]; // different than pc for indexing into the BRAM

  logic [31:0] inst_fetched;
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(128),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(data/inst.mem))           // Specify name/location of RAM initialization file if using one (leave blank if not)
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

  // registers (part of decode)
  register_file registers(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .rs1_in(rs1),
    .rs2_in(rs2),
    .wa_in(wa),
    .we_in(we),
    .wd_in(wd),

    .rd1_out(rval1), //available 1 clock cycle later
    .rd2_out(rval2)
  );

  // execute
  logic signed [31:0] rval1, rval2;

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
    .rval1_in(rval1),
    .rval2_in(rval2),

    .data_out(result),
    .addr_out(addr),
    .nextPc_out(nextPc)
  );

  // data memory
  logic[31:0] mem_addr;
  logic[11:0] effective_mem_addr;
  logic signed [31:0] mem_output;
  logic writing;

  logic signed [31:0] rval1_mem, rval2_mem;
  logic signed imm_mem;
  logic [3:0] iType_mem;
  logic signed [31:0] result_mem;
  logic [4:0] rd_mem;

  assign mem_addr = rval1_exe + imm_mem;
  assign effective_mem_addr = mem_addr[13:2];
  assign writing = (iType_mem == STORE) ? 1 : 0;
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(4096),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) data_mem (
    .addra(effective_mem_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(result_exe),       // RAM input data, width determined from RAM_WIDTH
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

  logic signed [31:0] result_write;

  assign wd = (iType_write == LOAD) ? mem_output_write : result_write;
  assign wa = rd_write;
  assign we = (iType_write != BRANCH) && (iType_write != STORE) && (rd_write != 0);
endmodule

`default_nettype wire