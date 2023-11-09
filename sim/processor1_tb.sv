`timescale 1ns / 1ps
`default_nettype none

module processor_tb();

  logic clk_in;
  logic rst_in;
  logic [31:0] instruction;
  logic signed [31:0] data_out;
  logic [31:0] addr_out;
  logic [31:0] nextPc_out;

  processor uut
          ( .clk_100mhz(clk_in),
            .rst_in(rst_in),
            .instruction(instruction),
            .data_out(data_out),
            .addr_out(addr_out),
            .nextPc_out(nextPc_out)
          );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("processor.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,processor_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    for (int i = 0; i<128; i=i+1)begin
      instruction = 32'h0015_8593;
      #10;
    end
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
