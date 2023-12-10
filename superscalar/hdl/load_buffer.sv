`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
`include "hdl/types.svh"

module load_buffer(
  input wire clk_in,
  input wire rst_in,
  input wire valid_input_in,

  // Inputs
  logic wire signed [31:0] dest_in,
  logic wire signed [31:0] rob_ix_in,

  // Pass this to memory unit
  output logic signed [31:0] data_out,
  output logic valid_out
);

  localparam LOAD_BUFFER_DEPTH = 3;

  logic signed [31:0] dest_row [LOAD_BUFFER_DEPTH-1:0];
  logic [2:0] rob_ix_row [LOAD_BUFFER_DEPTH-1:0];

  always_ff @posedge(clk_in) begin
    if (rst_in) begin
    end else begin
    end
  end


endmodule // reservation station

`default_nettype wire
