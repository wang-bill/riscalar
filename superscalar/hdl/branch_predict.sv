`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"
module branch_predict 
  (
    input wire clk_in,
    input wire rst_in,
    input wire signed [31:0] pc_in,
    output logic branch_taken_out
  );
  
  localparam LHT_DEPTH = 8;
  localparam LP_DEPTH = 4;

  localparam GLOBAL_DEPTH = 8;
  localparam CHOICe_DEPTH = 4;

  logic local_history_table 

  always_ff @(posedge clk_in) begin
    if (rst_in)
  end

endmodule
`default_nettype wire