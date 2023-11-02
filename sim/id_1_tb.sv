`timescale 1ns / 1ps
`default_nettype none

/*
0x00D605B3 // add a1, a2, a3
0x00158593 // addi a1, a1, 1
0x08E6A223 // sw a3, 4(a4)
lw
bne
jal
lui
auipc
*/
module id_tb();
  logic clk_in;
  logic [31:0] instruction_in;
  logic [31:0] pc;
  IType iType;
  AluFunc aluFunc;
  BrFunc brFunc;

  logic [31:0] updated_pc; // should be same as original pc
  logic [31:0] imm;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;

  logic iType_c;
  logic aluFunc_c;
  logic brFunc_c;
  logic updated_pc_c;
  logic imm_c;
  logic rs1_c;
  logic rs2_c;
  logic rd_c;
  
  decode uut(
    .clk_in(clk_in),
    .instruction_in(instruction_in),
    .pc_in(pc),

    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .pc_out(updated_pc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2),
    .rd_out(rd)
  );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end


  //initial block...this is our test simulation
  initial begin

    $display("Starting Sim");
    
    instruction_in = 32'h00D605B3; // add a1, a2, a3
    pc = 32'h0000_1111;
    #10

    iType_c = (iType == OP);
    aluFunc_c = (aluFunc == Add);
    updated_pc_c = (updated_pc == pc);
    rs1_c = (rs1 == 12);
    rs2_c = (rs2 == 13);
    rd_c = (rd == 11);

    $display("TEST 1: %s", (iType_c && updated_pc_c && aluFunc_c && rs1_c && rs2_c && rd_c) ? "PASSED" : "FAILED");
    
    instruction_in = 32'h00158593; // addi a1, a1, 1
    pc = 32'h0000_0000;
    #10
    
    iType_c = (iType == OPIMM);
    aluFunc_c = (aluFunc == Add);
    updated_pc_c = (updated_pc == pc);
    imm_c = (imm == 1);
    rs1_c = (rs1 == 11);
    rd_c = (rd == 11);

    $display("TEST 2: %s", (iType_c && updated_pc_c && aluFunc_c && imm_c && rs1_c && rd_c) ? "PASSED" : "FAILED");

    // instruction_in = 32'h08E6A223;
    // pc = 32'h1111_1111;
    // #10

    // iType_c = (iType == STORE);
    // aluFunc_c = (aluFunc == Add);
    // updated_pc_c = (updated_pc == pc);
    // imm_c = (imm == 4);
    // // rs1_c = (rs1 == 14);
    // // rs2_c = (rs2 == 13);
    // $display("%b", imm);
    // $display("TEST 3: %s", (iType_c && aluFunc_c && updated_pc_c && imm_c) ? "PASSED" : "FAILED");

    $finish;
  end
endmodule
`default_nettype wire
