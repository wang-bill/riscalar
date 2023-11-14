`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc;
`include "hdl/types.svh"

module branchAlu_tb();

  logic signed [31:0] rval1_in;
  logic signed [31:0] rval2_in;
  logic [2:0] brFunc_in;
  logic bool_out;

  logic passed;

  branchAlu uut(
    .rval1_in(rval1_in),
    .rval2_in(rval2_in),
    .brFunc_in(brFunc_in),
    .bool_out(bool_out)
  );

  //initial block...this is our test simulation
  initial begin
    // $dumpfile("recorder_tb.vcd"); //file to store value change dump (vcd)
    // $dumpvars(0,recorder_tb);
    $display("Starting Sim"); //print nice message at start
    rval1_in = 12;
    rval2_in = 10;
    brFunc_in = Eq;
    #10
    passed = bool_out == (rval1_in==rval2_in);
    $display("EQ TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 12;
    rval2_in = 10;
    brFunc_in = Neq;
    #10
    passed = bool_out == (rval1_in!=rval2_in);
    $display("NEQ TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = -5;
    rval2_in = 10;
    brFunc_in = Lt;
    #10
    passed = bool_out == (rval1_in < rval2_in);
    $display("LT TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = -5;
    rval2_in = 10;
    brFunc_in = Ltu;
    #10
    passed = bool_out == (rval1_in >= rval2_in);
    $display("LTU TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 12;
    rval2_in = -10;
    brFunc_in = Ge;
    #10
    passed = bool_out == (rval1_in >= rval2_in);
    $display("NEQ TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 12;
    rval2_in = -10;
    brFunc_in = Geu;
    #10
    passed = bool_out == (rval1_in < rval2_in);
    $display("NEQ TEST: %s", passed ? "PASSED" : "FAILED");

    rval1_in = 12;
    rval2_in = -10;
    brFunc_in = Dbr;
    #10
    passed = bool_out == (0);
    $display("NEQ TEST: %s", passed ? "PASSED" : "FAILED");
    $finish;
  end
endmodule
`default_nettype wire
