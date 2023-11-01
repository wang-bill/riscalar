`timescale 1ns / 1ps
`default_nettype none

/*
0x00D605B3 // add a1, a2, a3
0x00158593 // addi a1, a1, 1
0x0AE6A2A3 // sw a3, 5(a4)
*/
module id_tb();
  typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC} IType; //9 ITypes
  typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
  typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc;
  // 10 instructions from different categories
  // logic [31:0] instruction_in_1 = 32'h00D605B3;
  logic [31:0] instruction_in_2;
  // 32'h00158593;
  logic [31:0] pc;
  // 32'h0000_0000;
  // logic [31:0] instruction_in_3 = 32'h0AE6A2A3;

  Itype iType;
  AluFunc aluFunc;
  BrFunc brFunc;
  logic [31:0] imm;

  decode decode1(
    .clk_in(clk_in),
    .instruction_in(instruction_in_2),
    .pc_in(pc),

    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .pc_out(pc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2),
  );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end

  //initial block...this is our test simulation
  initial begin

    $display("Starting Sim");
    // call instructions and assert their output
    instruction_in_2 = 32'h00158593;
    pc = 32'h0000_0000;
    #10
    $display("no errors");
  end
endmodule
`default_nettype wire
