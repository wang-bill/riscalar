`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs

module alu_tb();

  logic signed [31:0] rval1_in;
  logic signed [31:0] rval2_in;
  logic [31:0] aluFunc_in;
  logic signed [31:0] data_out;

  logic passed;

  alu uut(
    .rval1_in(rval1_in),
    .rval2_in(rval2_in),
    .aluFunc_in(aluFunc_in),
    .data_out(data_out)
  );

  //initial block...this is our test simulation
  initial begin
    // $dumpfile("recorder_tb.vcd"); //file to store value change dump (vcd)
    // $dumpvars(0,recorder_tb);
    $display("Starting Sim"); //print nice message at start
    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = Add;
    #10
    passed = data_out == 22 ? 1 : 0;
    $display("ADD TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = Sub;
    #10
    passed = data_out == 2 ? 1 : 0;
    $display("SUB TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 27;
    rval2_in = 15;
    aluFunc_in = And;
    #10
    passed = data_out == 11 ? 1 : 0;
    $display("AND TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 27;
    rval2_in = 15;
    aluFunc_in = Or;
    #10
    passed = data_out == 31 ? 1 : 0;
    $display("OR TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 12;
    rval2_in = 12;
    aluFunc_in = Slt;
    #10
    passed = data_out == 0 ? 1 : 0;
    rval1_in = 12;
    rval2_in = 13;
    aluFunc_in = Slt;
    #10
    passed = passed && (data_out == 1) ? 1 : 0;
    $display("SLT TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 12;
    rval2_in = 12;
    aluFunc_in = Sltu;
    #10
    passed = data_out == 0 ? 1 : 0;
    $display("SLTU TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 8;
    rval2_in = 1;
    aluFunc_in = Srl;
    #10
    passed = data_out == 4 ? 1 : 0;
    $display("SRL TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 8;
    rval2_in = 1;
    aluFunc_in = Sra;
    #10
    passed = data_out == 4 ? 1 : 0;
    $display("SRA TEST: %s", passed ? "PASSED" : "FAILED");

    $finish;
  end
endmodule
`default_nettype wire
