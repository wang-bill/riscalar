`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

module processor(
  input wire clk_100mhz,
  input wire rst_in,

  input wire [31:0] instruction,
  output logic signed [31:0] data_out,
  output logic [31:0] addr_out,
  output logic [31:0] nextPc_out
);
  // instruction fetch
  logic [31:0] inst;
  logic [31:0] pc;

  always_ff @(posedge clk_100mhz) begin
    if (rst_in) begin
      //Simulates instruction fetch
      pc <= 32'h0000_0000; // hard coded for now
      inst <= 0; // hard coded for now, addi a1, a1, 1
    end else begin
      pc <= nextPc;
      inst <= instruction;
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

  decode my_decode(
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

  // registers (part of decode)
  logic signed [31:0] rval1, rval2, wd;
  logic [4:0] wa;
  logic we;

  register_file my_registerfile(
    .clk_in(clk_100mhz),
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
  execute my_execute(
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

  // memory
  // if (iType == LOAD || iType == STORE) begin
  //   // emulate memory
  // end

  // writeback
  assign wd = result;
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