`timescale 1ns / 1ps
`default_nettype none

module multiplier #(parameter ROB_IX=2)
(
  input wire clk_in,
  input wire rst_in,
  input wire flush_in,
  input wire valid_in, // high for 1 clock cycle
  input wire read_in,
  
  input wire signed [31:0] rval1_in,
  input wire signed [31:0] rval2_in,
  input wire [ROB_IX:0] rob_ix_in,

  output logic [ROB_IX:0] rob_ix_out,
  output logic signed [31:0] data_out,
  output logic ready_out,
  output logic valid_out // high until output is read
);
  localparam LATENCY = 6; //6 clock cycles for multiplier to generate output
  localparam COUNTER_SIZE = $clog2(LATENCY);
  
  logic [COUNTER_SIZE-1:0] counter;
  logic calculating;
  logic old_calculating;
  logic signed [31:0] a_val;
  logic signed [31:0] b_val;
  logic signed [31:0] p0;
  logic signed [31:0] p1;
  logic signed [31:0] p2;
  logic signed [31:0] p3;
  logic signed [31:0] p4;

  always_ff @(posedge clk_in) begin
    if (rst_in || flush_in) begin
      counter <= 0;
      p0 <= 0;
      p1 <= 0;
      p2 <= 0;
      p3 <= 0;
      p4 <= 0;
    end else begin
      if (valid_in) begin
        counter <= 1;
        rob_ix_out <= rob_ix_in;
        p0 <= rval1_in * rval2_in;
      end else if (counter >= 1'b1 && counter <= LATENCY-1) begin
        p1 <= p0;
        p2 <= p1;
        p3 <= p2;
        p4 <= p3;
        data_out <= p4;
        counter <= counter + 1;
      end else if (valid_out && read_in) begin
        counter <= 0;
        p0 <= 0;
        p1 <= 0;
        p2 <= 0;
        p3 <= 0;
        p4 <= 0;
      end
    end
  end

  always_comb begin
    valid_out = (counter == LATENCY);
    ready_out = counter == 0;
  end

  // mult_gen_1 mult(
  //   .CLK(clk_in),
  //   .A(rval1_in),
  //   .B(rval2_in),
  //   .P(data_out)
  // );
endmodule