`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
`include "hdl/types.svh"

module reservation_station(
    input wire clk_in,
    input wire rst_in,
    input wire valid_input_in, // input is valid
    input wire fu_busy_in, // corresponding functional unit is busy
    input wire [2:0] Q_i_in, //ROB entry number (ROB has size 8)
    input wire [2:0] Q_j_in,
    input wire signed [31:0] V_i_in,
    input wire signed [31:0] V_j_in,
    input wire [2:0] rob_idx_in,
    input wire [3:0] opcode_in,
    input wire i_ready,
    input wire j_ready,

    output logic signed [31:0] rval1_out,
    output logic signed [31:0] rval2_out,
    output logic [3:0] opcode_out,
    output logic [2:0] rob_idx_out,
    output logic rs_free_for_input_out, // tells whether reservation station is ready for another input
    output logic rs_output_valid_out // output from RS is valid
);

  localparam RS_DEPTH = 3;

  logic [2:0] Q_i_row [RS_DEPTH-1:0];
  logic [2:0] Q_j_row [RS_DEPTH-1:0];
  logic [31:0] V_i_row [RS_DEPTH-1:0];
  logic [31:0] V_j_row [RS_DEPTH-1:0];

  logic [2:0] rob_idx_row [RS_DEPTH-1:0];
  logic [3:0] opcode_row [RS_DEPTH-1:0];
  logic [RS_DEPTH-1:0] busy_row; // 1: busy, 0: not busy

  logic [$clog2(RS_DEPTH):0] open_row;
  logic [7:0] occupied_row;

  logic [2:0] i_ready_row;
  logic [2:0] j_ready_row;

  logic row_ready; // whether any entry in the RS is ready to be sent to FU

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      busy_row <= 0;
      rs_free_for_input_out <= 1;
    end else begin
      if (valid_input_in && rs_free_for_input_out) begin // rs_free_for_input_out check is technically not needed, but put just in case -- verifies that input is going into valid row
        // putting value into reservation station
        Q_i_row[open_row] <= Q_i_in;
        Q_j_row[open_row] <= Q_j_in;
        V_i_row[open_row] <= V_i_in;
        V_j_row[open_row] <= V_j_in;

        rob_idx_row[open_row] <= rob_idx_in;
        opcode_row[open_row] <= opcode_in;

        busy_row[open_row] <= 1;

        i_ready_row[open_row] <= i_ready;
        j_ready_row[open_row] <= j_ready;
      end

      if (!fu_busy_in && row_ready) begin
        // extracting value from reservation station
        rval1_out <= V_i_row[occupied_row];
        rval2_out <= V_j_row[occupied_row];
        opcode_out <= opcode_row[occupied_row];
        rob_idx_out <= rob_idx_row[occupied_row];
        busy_row[occupied_row] <= 0;
        rs_output_valid_out <= 1;
      end else begin
        rs_output_valid_out <= 0;
      end
    end
  end

  always_comb begin
    open_row = RS_DEPTH;
    for (int i = RS_DEPTH - 1; i >= 0; i = i-1) begin // iterating through backwards to maintain order
      open_row = !busy_row[i] ? i : open_row;
    end
    rs_free_for_input_out = !(open_row == RS_DEPTH);

    occupied_row = RS_DEPTH;
    for (int i = 0; i < RS_DEPTH; i = i + 1) begin
      occupied_row = (i_ready && j_ready && busy_row[i]) ? i : occupied_row;
    end
    row_ready = !(occupied_row == RS_DEPTH);
  end


endmodule // reservation station

`default_nettype wire