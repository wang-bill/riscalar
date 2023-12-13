`timescale 1ns / 1ps
`default_nettype none

module load_tb();

  logic clk_in;
//  logic [15:0] sw;
  logic [3:0] btn_in;
  // logic [31:0] instruction;
  // logic iq_valid;

  logic [15:0] led_out;
  logic [2:0] rgb0_out, rgb1_out;
  logic signed [31:0] data_out;
  logic [31:0] addr_out;
  logic [31:0] nextPc_out;

  top_level uut
          ( .clk_100mhz(clk_in),
            .btn(btn_in),

            .led(led_out),
            .rgb0(rgb0_out),
            .rgb1(rgb1_out)
          );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("load_tb.vcd");
    $dumpvars(0,load_tb);

    clk_in = 1;
    btn_in = 0;
    #10;
    btn_in = 1;
    #10;
    btn_in = 0;


    for (int i = 0; i <200; i=i+1) begin
      #10;
      $display("%d", led_out);
    end
    $display("%d", led_out);
    $finish;
  end
endmodule
`default_nettype wire
