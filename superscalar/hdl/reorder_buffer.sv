`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"
// We default size of reorder buffer to be size 8

module rob#(parameter ROB_SIZE=8, parameter LOAD_BUFFER_DEPTH=3)(
    input wire clk_in,
    input wire rst_in,
    //Decode Inputs - used to check for value of operand in ROB but not in RF yet
    input wire [ROB_IX:0] decode_rob1_ix_in,
    input wire [ROB_IX:0] decode_rob2_ix_in,
    //Issue Inputs
    input wire valid_in,
    input wire [3:0] iType_in,
    input wire signed [31:0] value_in,
    input wire signed [31:0] dest_in, // Will be the register index unless working with store
    //CDB Inputs
    input wire [ROB_IX:0] cdb_rob_ix_in,
    input wire signed [31:0] cdb_value_in,
    input wire signed [31:0] cdb_dest_in,
    input wire cdb_valid_in,

    // Load Inputs
    // input wire [2:0] lb_rob_arr_ix_in [2:0],
    // input wire [ROB_IX:0] lb_rob_arr_ix_in [LOAD_BUFFER_DEPTH-1:0],
    input wire [(ROB_IX+1)*(LOAD_BUFFER_DEPTH)] lb_rob_arr_ix_in,
    input wire signed [32 * LOAD_BUFFER_DEPTH] lb_rob_arr_dest_in,
    // input wire signed [31:0] lb_rob_arr_dest_in [LOAD_BUFFER_DEPTH-1:0],
    // Store Input
    input wire store_read_in, // Goes high for one clock cycle once store content has taken in ROB outputs

    // Load Outputs
    output logic [ROB_IX:0] can_load_out,

    //Decode Outputs:
    output logic signed [31:0] decode_value1_out,
    output logic decode_ready1_out,
    output logic signed [31:0] decode_value2_out,
    output logic decode_ready2_out,
    //Issue Output
    output logic [ROB_IX:0] inst_rob_ix_out,
    //Commit Outputs
    output logic [ROB_IX:0] ix_out, 
    output logic [3:0] iType_out,
    output logic signed [31:0] value_out,
    output logic signed [31:0] dest_out,

    output logic ready_out, //tells the input (CDB) that the ROB has space for more inputs
    output logic commit_out, //signal that goes high when the ROB's head can be committed to the Register File
    output logic store_valid_out, //signal that goes high when store outputs are valid

    output logic flush_out,
    output logic [4:0] flush_addrs_out [ROB_SIZE-1:0],
    output logic signed [31:0] nextPc_out,
    output logic valid_branch_out
);
  localparam ROB_IX = $clog2(ROB_SIZE)-1;
  logic [3:0] iType_buffer [ROB_SIZE-1:0];
  logic signed [31:0] value_buffer [ROB_SIZE-1:0];
  logic signed [31:0] destination_buffer [ROB_SIZE-1:0];
  logic signed [31:0] destination_buffer0;
  logic signed [31:0] destination_buffer1;
  logic [ROB_SIZE-1:0] inst_ready_buffer;
  logic correct_branch;


  logic [31:0] tail;
  logic [31:0] head;
  logic [31:0] instruction_queue [ROB_SIZE-1:0];
  //TODO: Is it safe to assume that we never will write from the CDB to the ROB in the same clk cycle?
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      tail <= 0;
      head <= 0;
      flush_out <= 0;
      for (int i = 0; i < ROB_SIZE; i = i+1) begin
        inst_ready_buffer[i] <= 1'b0;
      end
    end else if (correct_branch) begin
      if (ready_out && valid_in) begin
        iType_buffer[tail[ROB_IX:0]] <= iType_in;
        value_buffer[tail[ROB_IX:0]] <= value_in;
        destination_buffer[tail[ROB_IX:0]] <= dest_in;
        inst_ready_buffer[tail[ROB_IX:0]] <= 1'b0;
        tail <= tail + 1;
      end
      if (cdb_valid_in) begin
        if (iType_buffer[cdb_rob_ix_in] != BRANCH) begin
          value_buffer[cdb_rob_ix_in] <= cdb_value_in;
          if (iType_buffer[cdb_rob_ix_in] == STORE) begin
            destination_buffer[cdb_rob_ix_in] <= destination_buffer[cdb_rob_ix_in] + cdb_dest_in;
          end
        end
        inst_ready_buffer[cdb_rob_ix_in] <= 1'b1;
      end
      if (commit_out) begin
        head <= head + 1;
      end
      if (store_valid_out && store_read_in) begin
        head <= head + 1;
      end
    end else begin
      // Flushing the ROB
      flush_out <= 1;
      for (int i = 0; i < ROB_SIZE; i = i+1) begin
        if (i >= head[2:0] && i < tail) begin
          if (iType_buffer[i] == OPIMM || iType_buffer[i] == OP 
              || iType_buffer[i] == LUI || iType_buffer[i] == JAL
              || iType_buffer[i] == JALR || iType_buffer[i] == LOAD
              || iType_buffer[i] == MUL || iType_buffer[i] == DIV) begin
            flush_addrs_out[i] <= destination_buffer[i];
              end else begin
                flush_addrs_out[i] <= 0;
              end
        end else begin
          flush_addrs_out[i] <= 0;
        end
      end
      tail <= cdb_rob_ix_in;
    end
  end

  // logic [31:0] value_buffer0;
  // logic [31:0] value_buffer1;
  // logic [31:0] value_buffer2;
  // logic [31:0] value_buffer3;
  // logic [31:0] value_buffer4;
  // logic [31:0] value_buffer5;
  // logic [31:0] value_buffer6;
  // logic [31:0] value_buffer7;
  
  // logic [3:0] iType_buffer0;
  // logic [3:0] iType_buffer1;
  // logic [3:0] iType_buffer2;
  // logic [3:0] iType_buffer3;
  // logic [3:0] iType_buffer4;
  // logic [3:0] iType_buffer5;
  // logic [3:0] iType_buffer6;
  // logic [3:0] iType_buffer7;

  always_comb begin
    ready_out = (tail - head) < ROB_SIZE;
    commit_out = ((tail - head) > 0) && inst_ready_buffer[head[ROB_IX:0]] && iType_buffer[head[ROB_IX:0]] != STORE;
    store_valid_out = ((tail - head) > 0) && inst_ready_buffer[head[ROB_IX:0]] && iType_buffer[head[ROB_IX:0]] == STORE;

    ix_out = head[ROB_IX:0];
    iType_out = iType_buffer[head[ROB_IX:0]];
    value_out = value_buffer[head[ROB_IX:0]];
    dest_out = destination_buffer[head[ROB_IX:0]];
    inst_rob_ix_out = tail[ROB_IX:0];
    decode_value1_out = value_buffer[decode_rob1_ix_in];
    decode_ready1_out = inst_ready_buffer[decode_rob1_ix_in];
    decode_value2_out = value_buffer[decode_rob2_ix_in];
    decode_ready2_out = inst_ready_buffer[decode_rob2_ix_in];
    if (cdb_valid_in && iType_buffer[cdb_rob_ix_in] == BRANCH) begin
      valid_branch_out = 1;
      correct_branch = (value_buffer[cdb_rob_ix_in][0] == cdb_value_in);
    end else begin
      valid_branch_out = 0;
      correct_branch = 1;
    end
    nextPc_out = (!correct_branch) ? destination_buffer[cdb_rob_ix_in]: 0;
    // value_buffer0 = value_buffer[0];
    // value_buffer1 = value_buffer[1];
    // value_buffer2 = value_buffer[2];
    // value_buffer3 = value_buffer[3];
    // value_buffer4 = value_buffer[4];
    // value_buffer5 = value_buffer[5];
    // value_buffer6 = value_buffer[6];
    // value_buffer7 = value_buffer[7];
    // iType_buffer0 = iType_buffer[0];
    // iType_buffer1 = iType_buffer[1];
    // iType_buffer2 = iType_buffer[2];
    // iType_buffer3 = iType_buffer[3];
    // iType_buffer4 = iType_buffer[4];
    // iType_buffer5 = iType_buffer[5];
    // iType_buffer6 = iType_buffer[6];
    // iType_buffer7 = iType_buffer[7];
    // destination_buffer0 = destination_buffer[0];
    // destination_buffer1 = destination_buffer[1];
  end

  logic can_load_i;
  always_comb begin // Check from head to see if there are conflicts
    for (int i = 0; i <= ROB_IX; i=i+1) begin
      can_load_i = 1;
      for (int j = 0; j < ROB_SIZE; j = j+1) begin
        if (j >= head[ROB_IX:0] && j <= lb_rob_arr_ix_in[i*ROB_SIZE+j]) begin
          for (int k = 0; k < 32; k=k+1) begin
            can_load_i &= !(iType_buffer[j] == STORE &&
                          destination_buffer[j][k] ==
                          lb_rob_arr_dest_in[i*ROB_SIZE+k]);
          end
          
          // can_load_i &= !(iType_buffer[j] == STORE && 
                        // (destination_buffer[j] ==
                        // lb_rob_arr_dest_in[i*ROB_SIZE+31:i*ROB_SIZE]));
          can_load_i &= !(iType_buffer[j] == STORE && !inst_ready_buffer[j]);
        end
      end
      can_load_out[i] = can_load_i;
    end
  end
endmodule //rob

`default_nettype wire
