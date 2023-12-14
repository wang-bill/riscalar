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

  localparam GAC_DEPTH = 8; // global and choice depth

  logic [$clog2(LP_DEPTH)-1:0] local_history_table [LHT_DEPTH-1:0];
  logic [1:0] local_prediction_table [LP_DEPTH-1:0];

  logic [1:0] global_prediction_table [GAC_DEPTH-1:0];
  logic [1:0] choice_prediction_table [GAC_DEPTH-1:0];

  logic [$clog2(GAC_DEPTH)-1:0] path_history;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      for (int i = 0; i < LHT_DEPTH; i=i+1) begin
        local_history_table[i] <= 0;
      end
      for (int i = 0; i < LP_DEPTH; i=i+1) begin
        local_prediction_table[i] <= 0;
      end
      for (int i = 0; i < GAC_DEPTH; i=i+1) begin
        global_prediction_table[i] <= 0;
        choice_prediction_table[i] <= 0;
      end
      branch_taken_out <= 0;
      path_history <= 0;
    end else begin
      if (update_valid_in) begin
        if (correct_branch) begin
          path_history <= {path_history[$clog2(GAC_DEPTH)-2:0], 1'b1};
          choice_prediction_table[path_history] <= choice_prediction_table[path_history] != 3 ? choice_prediction_table[path_history] + 1 : choice_prediction_table[path_history];
          global_prediction_table[path_history] <= global_prediction_table[path_history] != 3 ? global_prediction_table[path_history] + 1 : global_prediction_table[path_history];

          local_prediction_table[local_history_table[prediction_pc]] <= local_prediction_table[local_history_table[prediction_pc]] != 3 ? local_prediction_table[local_history_table[prediction_pc]] + 1 : local_prediction_table[local_history_table[prediction_pc]];

        end else begin
          path_history <= {path_history[$clog2(GAC_DEPTH)-2:0], 1'b0};
          choice_prediction_table[path_history] <= choice_prediction_table[path_history] != 0 ? choice_prediction_table[path_history] - 1 : choice_prediction_table[path_history];
          global_prediction_table[path_history] <= global_prediction_table[path_history] != 0 ? global_prediction_table[path_history] - 1 : global_prediction_table[path_history];

          local_prediction_table[local_history_table[prediction_pc]] <= local_prediction_table[local_history_table[prediction_pc]] != 0 ? local_prediction_table[local_history_table[prediction_pc]] - 1 : local_prediction_table[local_history_table[prediction_pc]];
        end

      end
    end
  end

  logic [$clog2(LHT_DEPTH)-1:0] local_history_table_ix;
  logic [$clog2(LP_DEPTH)-1:0] local_prediction_table_ix;
  logic local_predict, global_predict;
  logic [$clog2(LHT_DEPTH)-1:0] prediction_pc;
  always_comb begin
    local_history_table_ix = pc_in[$clog2(LHT_DEPTH)-1:0];
    local_prediction_table_ix = local_history_table[local_history_table_ix];
    local_predict = local_prediction_table[local_prediction_table_ix][1];

    global_predict = global_prediction_table[path_history][1];

    branch_taken_out = choice_prediction_table[path_history] ? global_predict : local_predict;
  
    prediction_pc = pc_in[$clog2(LHT_DEPTH)-1:0];
  end

endmodule
`default_nettype wire