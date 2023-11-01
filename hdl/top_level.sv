`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
)

  // instruction fetch
  logic [31:0] pc;
  logic [31:0] inst;

  assign inst = 32'h0015_8593; // hard coded for now, addi a1, a1, 1
  assign pc = 32'h0000_0000; // hard coded for now

  // decode
  Itype iType;
  AluFunc aluFunc;
  BrFunc brFunc;
  logic signed [31:0] imm;
  logic [4:0] rs1;
  logic [4:0] rs2;

  decode(
    .clk_in(clk_100mhz),
    .instruction_in(inst), // fill in from fetch
    .pc_in(pc), // fill in from fetch

    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .pc_out(pc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2)
  );

  // registers (part of decode)
  logic signed [31:0] rval1, rval2, wd;
  logic [4:0] wa;
  logic we;

  register_file(
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

  // execute
  execute(
    .iType_in(iType),
    .aluFunc_in(aluFunc),
    .brFunc_in(brFunc),
    .imm_in(imm),
    .pc_in(pc),
    .rval1_in(rval1),
    .rval2_in(rval2),

    .data_out(),
    .addr_out(),
    .nextPc_out()
  );

  // memory

  // writeback

endmodule

`default_nettype wire