`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"
// We default size of reorder buffer to be size 8

module rob#(parameter SIZE=8)(
    input wire clk_in,
    input wire rst_in,
    //Decode Inputs - used to check for value of operand in ROB but not in RF yet
    input wire [2:0] decode_rob1_ix_in,
    input wire [2:0] decode_rob2_ix_in,
    //Issue Inputs
    input wire valid_in,
    input wire [3:0] iType_in,
    input wire signed [31:0] value_in,
    input wire signed [31:0] dest_in,
    //CDB Inputs
    input wire [PTR_SIZE-1:0] cdb_rob_ix_in,
    input wire signed [31:0] cdb_value_in,
    input wire signed [31:0] cdb_dest_in,
    input wire cdb_valid_in,
    //Decode Outputs:
    output logic signed [31:0] decode_value1_out,
    output logic decode_ready1_out,
    output logic signed [31:0] decode_value2_out,
    output logic decode_ready2_out,
    //Issue Output
    output logic [PTR_SIZE-1:0] inst_rob_ix_out,
    //Commit Outputs
    output logic [2:0] ix_out, 
    output logic [3:0] iType_out,
    output logic signed [31:0] value_out,
    output logic signed [31:0] dest_out,

    output logic ready_out, //tells the input (CDB) that the ROB has space for more inputs
    output logic commit_out //signal that goes high when the ROB's head can be committed to the Register File
);
  localparam PTR_SIZE = $clog2(SIZE);
  logic [3:0] iType_buffer [SIZE-1:0];
  logic signed [31:0] value_buffer [SIZE-1:0];
  logic signed [31:0] destination_buffer [SIZE-1:0];
  logic [SIZE-1:0] inst_ready_buffer;
  logic [31:0] value_buffer0;
  logic [31:0] value_buffer1;
  logic [31:0] value_buffer2;
  logic [31:0] value_buffer3;
  logic [31:0] value_buffer4;
  logic [31:0] value_buffer5;
  logic [31:0] value_buffer6;
  logic [31:0] value_buffer7;
  
  logic [3:0] iType_buffer0;
  logic [3:0] iType_buffer1;
  logic [3:0] iType_buffer2;
  logic [3:0] iType_buffer3;
  logic [3:0] iType_buffer4;
  logic [3:0] iType_buffer5;
  logic [3:0] iType_buffer6;
  logic [3:0] iType_buffer7;

  logic [31:0] tail;
  logic [31:0] head;
  logic [31:0] instruction_queue [SIZE-1:0];
  //TODO: Is it safe to assume that we never will write from the CDB to the ROB in the same clk cycle?s
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      tail <= 0;
      head <= 0;
      for (int i = 0; i < PTR_SIZE; i = i+1) begin
        inst_ready_buffer[i] <= 1'b0;
      end
    end else begin
      if (ready_out && valid_in) begin
        iType_buffer[tail[2:0]] <= iType_in;
        value_buffer[tail[2:0]] <= value_in;
        destination_buffer[tail[2:0]] <= dest_in;
        inst_ready_buffer[tail[2:0]] <= 1'b0;
        tail <= tail + 1;
      end
      if (commit_out) begin
        head <= head + 1;
      end
      if (cdb_valid_in) begin
        value_buffer[cdb_rob_ix_in] <= cdb_value_in;
        if (iType_buffer[cdb_rob_ix_in] == STORE) begin
            destination_buffer[cdb_rob_ix_in] <= cdb_dest_in;
        end
        if (iType_buffer[cdb_rob_ix_in] != STORE) begin
          inst_ready_buffer[cdb_rob_ix_in] <= 1'b1;
        end else begin
          //handle store instructions separately 
        end 
      end
    end
  end
  always_comb begin
    ready_out = (tail - head) < SIZE;
    commit_out = ((tail - head) > 0) && inst_ready_buffer[head[2:0]];
    ix_out = head[2:0];
    iType_out = iType_buffer[head[2:0]];
    value_out = value_buffer[head[2:0]];
    dest_out = destination_buffer[head[2:0]];
    inst_rob_ix_out = tail[2:0];
    decode_value1_out = value_buffer[decode_rob1_ix_in];
    decode_ready1_out = inst_ready_buffer[decode_rob1_ix_in];
    decode_value2_out = value_buffer[decode_rob2_ix_in];
    decode_ready2_out = inst_ready_buffer[decode_rob2_ix_in];
    value_buffer0 = value_buffer[0];
    value_buffer1 = value_buffer[1];
    value_buffer2 = value_buffer[2];
    value_buffer3 = value_buffer[3];
    value_buffer4 = value_buffer[4];
    value_buffer5 = value_buffer[5];
    value_buffer6 = value_buffer[6];
    value_buffer7 = value_buffer[7];
    iType_buffer0 = iType_buffer[0];
    iType_buffer1 = iType_buffer[1];
    iType_buffer2 = iType_buffer[2];
    iType_buffer3 = iType_buffer[3];
    iType_buffer4 = iType_buffer[4];
    iType_buffer5 = iType_buffer[5];
    iType_buffer6 = iType_buffer[6];
    iType_buffer7 = iType_buffer[7];
  end
endmodule //rob

`default_nettype wire
