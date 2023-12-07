`timescale 1ns / 1ps
`default_nettype none

module multiplier_tb();
  logic clk_in;
  logic rst_in;
  logic valid_in, read_in;
  logic ready_out, valid_out;
  logic signed [31:0] rval1_in, rval2_in;
  logic signed [31:0] data_out;
  logic [2:0] rob_idx_in, rob_idx_out;

  logic signed [31:0] a_in, b_in;
  logic signed [63:0] product_out;
  logic signed [31:0] product_out_small;

  multiplier uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .valid_in(valid_in), // high for 1 clock cycle
    .read_in(read_in),
    
    .rval1_in(rval1_in),
    .rval2_in(rval2_in),
    .rob_idx_in(rob_idx_in),

    .rob_idx_out(rob_idx_out),
    .data_out(data_out),
    .ready_out(ready_out),
    .valid_out(valid_out) // high until output is read
  );
  mult_gen_0 mult(
    .CLK(clk_in),
    .A(a_in),
    .B(b_in),
    .P(product_out)
  );

  mult_gen_1 mult_pipelined10(
    .CLK(clk_in),
    .A(a_in),
    .B(b_in),
    .P(product_out_small)
  );

  always begin
    #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
    clk_in = !clk_in;
  end

  initial begin
    #5;
    clk_in = 1;
    #5;
    valid_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10;
    a_in = 32'h3;
    b_in = 32'h4;
    rval1_in = 32'h5;
    rval2_in = 32'h4;
    read_in = 0;
    rob_idx_in = 32'h0;
    for (int i = 0; i < 10; i = i+1) begin
      // $display("%d: %d  %d", i, product_out, product_out_small);
      if (i == 0) begin
        valid_in = 1;
      end else if (i == 1) begin
        valid_in = 0;
      end
      $display("%d: %d", i, data_out);
      #10;
    end
    $finish;
  end

endmodule //multiplier_tb