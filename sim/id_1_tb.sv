`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
/*
0x00D605B3 // add a1, a2, a3
0x00158593 // addi a1, a1, 1
0x0AE6A2A3 // sw a3, 5(a4)
*/


module id_tb();

  // 10 instructions from different categories
  logic [31:0] instruction_in_1 = 32'h00D605B3;
  logic [31:0] instruction_in_2 = 32'h00158593;
  logic [31:0] instruction_in_3 = 32'h0AE6A2A3;

  //initial block...this is our test simulation
  initial begin

    $display("Starting Sim");
    // call instructions and assert their output


  end
endmodule
`default_nettype wire
