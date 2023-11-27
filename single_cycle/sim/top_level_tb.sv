`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"X`"
`endif  /* ! SYNTHESIS */

module top_level_tb();

  logic clk_in;
  logic [15:0] sw;
  logic [3:0] btn;
  logic [15:0] led_out;

  top_level uut
          ( .clk_100mhz(clk_in),
            .sw(sw),
            .btn(btn),
            .led(led_out),
            .rgb0(),
            .rgb1()
          );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("top_level_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,top_level_tb); //store everything at the current level and below

    clk_in = 1;
    btn = 0;
    #10;
    btn = 1;
    #10;
    btn = 0;
    #10;

    for (int i = 0; i<10**3 + 4; i=i+1)begin
      //$display("%d\n", i);
      //$display("%d\n", led_out);
      //$display("===============");  
      #10;
    end

    $display("%d", led_out);

    $finish;
  end
endmodule
`default_nettype wire
