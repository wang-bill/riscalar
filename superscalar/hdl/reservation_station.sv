`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
`include "hdl/types.svh"

module reservation_station(
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire [31:0] Q_i_in,
    input wire [31:0] Q_j_in,
    input wire [31:0] V_i_in,
    input wire [31:0] V_j_n,
    input wire [2:0] rob_idx_in,
    input wire [3:0] opcode_in,

    output logic [31:0] rs1_out,
    output logic [31:0] rs2_out,
    output logic [3:0] opcode_out,
    output logic [2:0] rob_idx_out,
    output logic ready
);

  localparam RS_DEPTH = 3;

  logic [31:0] Q_i_row [RS_DEPTH-1:0];
  logic [31:0] Q_j_row [RS_DEPTH-1:0];
  logic [31:0] V_i_row [RS_DEPTH-1:0];
  logic [31:0] V_j_row [RS_DEPTH-1:0];

  logic [2:0] rob_idx_row [RS_DEPTH-1:0];
  logic [3:0] opcode_row [RS_DEPTH-1:0];
  logic busy_row [RS_DEPTH-1:0];

  always @(posedge clk_in) begin
    if (rst_in) begin
      // reset
    end else begin
      if (valid_in) begin
        
      end

    end
  end


endmodule // reservation station

`default_nettype wire
