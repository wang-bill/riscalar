`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

module foo_tb(); 
    IType itype_in;
    logic [3:0] result_out;

    foo uut(
        .itype_in(itype_in),
        .result_out(result_out)
    ); 

    initial begin
    // $dumpfile("recorder_tb.vcd"); //file to store value change dump (vcd)
    // $dumpvars(0,recorder_tb);
    $display("Starting Sim"); //print nice message at start
    itype_in = OP;
    #10
    $display("Input: OP Output: %d", result_out);

    $display("Starting Sim"); //print nice message at start
    itype_in = OPIMM;
    #10
    $display("Input: OPIMM Output: %d", result_out);

    $display("Starting Sim"); //print nice message at start
    itype_in = LUI;
    #10
    $display("Input: LUI Output: %d", result_out);

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire