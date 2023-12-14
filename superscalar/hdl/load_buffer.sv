`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
`include "hdl/types.svh"

module load_buffer
    #(parameter LOAD_BUFFER_DEPTH=3, 
      parameter ROB_SIZE=2)(
  input wire clk_in,
  input wire rst_in,
  input wire valid_input_in,

  // Inputs
  input wire signed [31:0] dest_in,
  input wire [2:0] rob_ix_in,
  input wire [2:0] can_load_in,
  input wire read_in,

  // Pass to ROB
  // output logic signed [31:0] lb_dest_out [2:0],
  output logic signed [31:0] lb_dest0_out,
  output logic signed [31:0] lb_dest1_out,
  output logic signed [31:0] lb_dest2_out,
  // output logic [2:0] lb_rob_arr_ix_out [2:0],
  output logic [2:0] lb_rob_arr_ix0_out,
  output logic [2:0] lb_rob_arr_ix1_out,
  output logic [2:0] lb_rob_arr_ix2_out,

  // Pass this to memory unit
  output logic signed [31:0] dest_out, // address calculated out
  output logic ready_out, // ready for another input
  output logic valid_out, // output is valid
  output logic [2:0] rob_ix_out
);

  localparam LOAD_BUFFER_DEPTH = 3; // if this is changed, the reorder buffer can_load value needs to change too

  logic signed [31:0] dest_row [LOAD_BUFFER_DEPTH-1:0];
  logic [2:0] rob_ix_row [LOAD_BUFFER_DEPTH-1:0];
  logic [LOAD_BUFFER_DEPTH-1:0] occupied_row;

  // assign lb_dest_out = dest_row;
  assign lb_dest0_out = dest_row[0];
  assign lb_dest1_out = dest_row[1];
  assign lb_dest2_out = dest_row[2];
  // assign lb_rob_arr_ix_out = rob_ix_row;
  assign lb_rob_arr_ix0_out = rob_ix_row[0];
  assign lb_rob_arr_ix1_out = rob_ix_row[1];
  assign lb_rob_arr_ix2_out = rob_ix_row[2];

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      // valid_out <= 0;
      // ready_out <= 1;
      occupied_row <= 0;
      for (int i = 0; i < LOAD_BUFFER_DEPTH; i = i+1) begin
        dest_row[i] <= 0;
      end
    end else begin
      // valid_out <= (can_load_in & occupied_row) != 0;
      if (valid_input_in) begin
        if (open_row != LOAD_BUFFER_DEPTH) begin // there is a row open
          rob_ix_row[open_row] <= rob_ix_in;
          dest_row[open_row] <= dest_in;
          occupied_row[open_row] <= 1;
        end 
        
        // else begin // all rows are occupied, so we can't accept the input
        //   ready_out <= 0;
        // end
      end
      if (valid_out && read_in) begin
        occupied_row[issued_row] <= 0;
      end
    end
  end

  logic [$clog2(LOAD_BUFFER_DEPTH)-1:0] open_row;
  always_comb begin // Fill 2 first, then 1, then 0
    open_row = LOAD_BUFFER_DEPTH;
    for (int i = 0; i < LOAD_BUFFER_DEPTH; i=i+1) begin
      if (!occupied_row[i]) begin
        open_row = i;
      end
    end
    ready_out = open_row != LOAD_BUFFER_DEPTH;
  end

  logic [$clog2(LOAD_BUFFER_DEPTH)-1:0] issued_row;
  always_comb begin
    issued_row = LOAD_BUFFER_DEPTH;
    for (int i = 0; i < LOAD_BUFFER_DEPTH; i=i+1) begin
      // check the rob stuff to see if we can send out
      if (can_load_in[i] && occupied_row[i]) begin
        dest_out = dest_row[i];
        rob_ix_out = rob_ix_row[i]; 
        issued_row = i;
      end
    end
  end

  assign valid_out = (can_load_in & occupied_row) != 0;
endmodule // load_buffer

`default_nettype wire
