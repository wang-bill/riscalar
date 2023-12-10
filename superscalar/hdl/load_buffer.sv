`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
`include "hdl/types.svh"

module load_buffer(
  input wire clk_in,
  input wire rst_in,
  input wire valid_input_in,

  // Inputs
  input logic wire signed [31:0] dest_in,
  input logic wire signed [31:0] rob_ix_in,
  input logic wire [2:0] can_load_in,

  // Pass to ROB
  output logic signed [31:0] lb_dest_out [2:0];
  output logic [2:0] lb_rob_arr_ix_out [2:0];

  // Pass this to memory unit
  output logic signed [31:0] data_out, // address calculated out
  output logic ready_out, // ready for another input
  output logic valid_out // output is valid

);

  localparam LOAD_BUFFER_DEPTH = 3; // if this is changed, the reorder buffer can_load value needs to change too

  logic signed [31:0] dest_row [LOAD_BUFFER_DEPTH-1:0];
  logic [2:0] rob_ix_row [LOAD_BUFFER_DEPTH-1:0];
  logic [LOAD_BUFFER_DEPTH-1] occupied_row;

  assign lb_dest_out = dest_row;
  assign lb_rob_arr_ix_out = rob_ix_row;

  always_ff @posedge(clk_in) begin
    if (rst_in) begin
      valid_out <= 0;
      ready_out <= 1;
      occupied_row <= 0;
    end else begin
      
      if (can_load != 0 && !read_in) begin
        valid_out <= 1;
      end else begin
        valid_out <= 0;
      end

      if (valid_input_in) begin
        if (open_row != LOAD_BUFFER_DEPTH) begin // there is a row open
          rob_ix_row[open_row] <= rob_ix_in;
          dest_row[open_row] <= dest_in;
        end 
        
        // else begin // all rows are occupied, so we can't accept the input
        //   ready_out <= 0;
        // end
      end
    end
  end

  logic [$clog2(RS_DEPTH)-1:0] open_row;
  always_comb begin // Fill 2 first, then 1, then 0
    open_row = LOAD_BUFFER_DEPTH;
    for (int i = 0; i < LOAD_BUFFER_DEPTH; i=i+1) begin
      if (!occupied_row[i]) begin
        open_row = i;
      end
    end
    ready_out = open_row != LOAD_BUFFER_DEPTH;
  end

  always_comb begin
    for (int i = 0; i < LOAD_BUFFER_DEPTH; i=i+1) begin
      // check the rob stuff to see if we can send out
      if (can_load[i]) begin
        data_out = dest_in;
      end
    end
  end


endmodule // reservation station

`default_nettype wire
