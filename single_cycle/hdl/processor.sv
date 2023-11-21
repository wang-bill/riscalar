`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"X`"
`endif  /* ! SYNTHESIS */

module processor(
  input wire clk_100mhz,
  input wire rst_in,

  output logic signed [31:0] data_out,
  output logic [31:0] addr_out,
  output logic [31:0] nextPc_out,
  output logic [31:0] registers_out
);

  // instruction fetch
  logic [31:0] pc;
  logic [31:0] inst;
  logic [11:0] effective_pc;
  logic wea_inst;

  logic past_single_cycle_clk;
  assign wea_inst = 0;
  assign effective_pc = pc[13:2];
  logic [31:0] inst_fetched;
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(128),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(data/inst.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_mem (
    .addra(effective_pc),     // Address bus, width determined from RAM_DEPTH
    // .dina(instruction_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(wea_inst),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(inst_fetched)      // RAM output data, width determined from RAM_WIDTH
  );
  
  logic [2:0] counter;
  logic single_cycle_clk;

  always_ff @(posedge clk_100mhz) begin
    if (rst_in) begin
      //Simulates instruction fetch
      pc <= 32'h0000_0000; // hard coded for now
      inst <= 0;
      counter <= 1;
      single_cycle_clk <= 0;
    end else begin
      if (counter == 4) begin
        single_cycle_clk <= !single_cycle_clk;
        counter <= 1;
        past_single_cycle_clk <= single_cycle_clk;
      end else begin
        counter <= counter + 1;
      end

      if (!past_single_cycle_clk && single_cycle_clk) begin
        pc <= nextPc;
        inst <= inst_fetched;
      end
    end
  end

  // decode
  logic [3:0] iType;
  logic [3:0] aluFunc;
  logic [2:0] brFunc;

  logic signed [31:0] imm;
  logic signed [4:0] rs1;
  logic signed [4:0] rs2;
  logic [4:0] rd;

  decode decoder(
   .instruction_in(inst), // fill in from fetch

    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2),
    .rd_out(rd)
  );

  // registers (part of decode)
  logic signed [31:0] rval1, rval2, wd;
  logic [4:0] wa;
  logic we;

  register_file registers(
    .clk_in(single_cycle_clk),
    .rst_in(rst_in),
    .rs1_in(rs1),
    .rs2_in(rs2),
    .wa_in(wa),
    .we_in(we),
    .wd_in(wd),

    .rd1_out(rval1),
    .rd2_out(rval2)
  );

  logic signed [31:0] result;
  logic [31:0] addr, nextPc; 

  // execute
  execute execute_module(
    .iType_in(iType),
    .aluFunc_in(aluFunc),
    .brFunc_in(brFunc),
    .imm_in(imm),
    .pc_in(pc),
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

  assign mem_addr = rval1 + imm;
  assign effective_mem_addr = mem_addr[13:2];
  assign writing = (iType == STORE) ? 1 : 0;
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(4096),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) data_mem (
    .addra(effective_mem_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(result),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(writing),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(mem_output)      // RAM output data, width determined from RAM_WIDTH
  );

  // writeback
  assign wd = (iType == LOAD) ? mem_output : result;
  assign wa = rd;
  // When we encounter a branch or store instruction, the destination register is unchanged
  // We also prevent writeback attempts to 0x0
  assign we = (iType != BRANCH) && (iType != STORE) && (rd != 0);

  //Testing Output:

  assign data_out = result;
  assign addr_out = addr;
  assign nextPc_out = nextPc;
endmodule

`default_nettype wire