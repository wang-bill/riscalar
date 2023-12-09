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
  assign branch_taken_out = 0;
endmodule
`default_nettype wire