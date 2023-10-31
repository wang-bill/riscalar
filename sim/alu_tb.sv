`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs

module alu_tb();

  logic signed [31:0] rval1_in;
  logic signed [31:0] rval2_in;
  logic [3:0] aluFunc_in;
  logic signed [31:0] data_out;

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
    $display("%d and %d with operation #%d = %d", rval1_in, rval2_in, aluFunc_in, data_out);

    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = Sub;
    #10
    $display("%d and %d with operation #%d = %d", rval1_in, rval2_in, aluFunc_in, data_out);

    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = And;
    #10
    $display("%d and %d with operation #%d = %d", rval1_in, rval2_in, aluFunc_in, data_out);

    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = Or;
    #10
    $display("%d and %d with operation #%d = %d", rval1_in, rval2_in, aluFunc_in, data_out);

    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = Slt;
    #10
    $display("%d and %d with operation #%d = %d", rval1_in, rval2_in, aluFunc_in, data_out);

    $display("Simulation finished");

    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = Sltu;
    #10
    $display("%d and %d with operation #%d = %d", rval1_in, rval2_in, aluFunc_in, data_out);

    $display("Simulation finished");

    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = Srl;
    #10
    $display("%d and %d with operation #%d = %d", rval1_in, rval2_in, aluFunc_in, data_out);

    $display("Simulation finished");

    rval1_in = 12;
    rval2_in = 10;
    aluFunc_in = Sra;
    #10
    $display("%d and %d with operation #%d = %d", rval1_in, rval2_in, aluFunc_in, data_out);

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
