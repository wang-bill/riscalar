`timescale 1ns / 1ps
`default_nettype none

module iq_to_cdb_tb();

  logic clk_in;
  logic [15:0] sw;
  logic [3:0] btn_in;
  logic [31:0] instruction;
  logic iq_valid;

  logic [15:0] led_out;
  logic [2:0] rgb0_out, rgb1_out;
  logic signed [31:0] data_out;
  logic [31:0] addr_out;
  logic [31:0] nextPc_out;

  top_level uut
          ( .clk_100mhz(clk_in),
            .sw(sw),
            .btn(btn_in),
            .instruction(instruction),
            .iq_valid(iq_valid),

            .led(led_out),
            .rgb0(rgb0_out),
            .rgb1(rgb1_out),
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
    $dumpfile("iq_to_cdb.vcd");
    $dumpvars(0,iq_to_cdb_tb);

    clk_in = 1;
    btn_in = 0;
    #10;
    btn_in = 1;
    #10;
    btn_in = 0;


    for (int i = 0; i < 10**3; i=i+1) begin
      #10;
      iq_valid = 0;
      if (i == 20) begin
        instruction = 32'h00158593; // addi a1, a1, 1
        iq_valid = 1;
      end
    end

    $display("%d", led_out);

    $finish;
  end
endmodule
`default_nettype wire