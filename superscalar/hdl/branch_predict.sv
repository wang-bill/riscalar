`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"
module branch_predict 
  (
    input wire clk_in,
    input wire rst_in,
    input wire signed [31:0] pc_in,
    input wire correct_branch,
    input wire update_valid_in,

    output logic branch_taken_out
  );
  
  localparam LHT_DEPTH = 8;
  localparam LP_DEPTH = 4;

  localparam GLOBAL_DEPTH = 8;
  localparam CHOICE_DEPTH = 4;

  logic [$clog2(LHT_DEPTH)-1:0] local_history_table [LHT_DEPTH-1:0];
  logic [1:0] local_prediction_table [LHT_DEPTH-1:0];

  logic [1:0] global_prediction_table [GLOBAL_DEPTH-1:0];
  logic [1:0] choice_prediction_table [CHOICE_DEPTH-1:0];

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      for (int i = 0; i < LHT_DEPTH; i=i+1) begin
        local_history_table[i] <= 0;
        local_prediction_table[i] <= 0;
      end
      for (int i = 0; i < GLOBAL_DEPTH; i=i+1) begin
        global_prediction_table[i] <= 0;
      end
      for (int i = 0; i < CHOICE_DEPTH; i=i+1) begin
        choice_prediction_table[i] <= 0;
      end

      branch_taken_out <= 0;
    end else begin
      
    end
  end

  logic [$clog2(LHT_DEPTH)-1:0] local_history_table_ix;
  always_comb begin
    local_history_table_ix = pc_in[$clog2(LHT_DEPTH)-1:0];
  logic local_history_table; 

  always_comb begin
    branch_taken_out = 0;
  end

endmodule
`default_nettype wire