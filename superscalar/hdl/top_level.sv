`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

`ifdef SYNTHESIS
`define FPATH(X) `"data/X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"X`"
`endif  /* ! SYNTHESIS */

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  input wire [3:0] btn,
  output logic [15:0] led,
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led

  input wire [31:0] instruction,
  output logic signed [31:0] data_out,
  output logic [31:0] addr_out,
  output logic [31:0] nextPc_out
);
  // assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1 = 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];
  
  logic signed [31:0] pc;
  logic signed [31:0] instruction_fetched, instruction_out, instruction_decode;
  logic valid, output_read;
  logic iq_ready, iq_inst_available;
  instruction_queue #(.SIZE(4)) inst_queue (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_in(valid),
    .output_read_in(output_read),
    .instruction_in(instruction_fetched),
    .inst_available_out(iq_ready),
    .instruction_out(instruction_out),
    .ready_out(iq_inst_available)
  );

  // decode
  logic [31:0] inst;
  logic[3:0] iType;
  logic[3:0] aluFunc;
  logic[2:0] brFunc;

  logic signed [31:0] imm;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;

  logic signed [31:0] pc_decode;

  decode decoder(
    .instruction_in(instruction_out), // fill in from fetch
    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2),
    .rd_out(rd)
  );
  

  // Convert from 109 bits to separate registers
  localparam BUSY_LOWER = 0;
  localparam ADDRESS_LOWER = 1;
  localparam VK_LOWER = 33;
  localparam VJ_LOWER = 65;
  localparam QK_LOWER = 97;
  localparam QJ_LOWER = 101;
  localparam OPERATION_LOWER = 105;

  logic [31:0] instruction_queue [5:0];

  // decode to find alu_opcode

  logic [108:0] reservation_station_1 [2:0]; // ALU 1
  logic [108:0] reservation_station_2 [1:0]; // ALU 2


  // ALU 1
  logic signed [31:0] alu1_Vj, alu1_Vk;
  logic signed [31:0] alu1_result;
  logic [3:0] alu1_opcode; // get from decode

  logic alu1_ready;

  // ALU 2
  logic signed [31:0] alu2_Vj, alu2_Vk;
  logic signed [31:0] alu2_result;
  logic [3:0] alu2_opcode; // get from decode

  logic alu2_ready;


  always_ff @(posedge clk_100mhz ) begin
    if (sys_rst) begin
    end
    //TODO: Refactor this to use genvar for loop
    if (reservation_station_1[0][BUSY_LOWER] && !reservation_station_1[0][QK_LOWER + 3 : QK_LOWER] &&
        !reservation_station_1[0][QJ_LOWER + 3 : QJ_LOWER]) begin
          if (alu1_ready) begin
            alu1_Vk <= reservation_station_1[0][VK_LOWER + 31 : VK_LOWER];
            alu1_Vj <= reservation_station_1[0][VJ_LOWER + 31 : VJ_LOWER];
            reservation_station_1[0][BUSY_LOWER] <= 0;

            alu1_result_reservation_station_row <= 0;
          end else if (alu2_ready) begin
            alu2_Vk <= reservation_station_2[0][VK_LOWER + 31 : VK_LOWER];
            alu2_Vj <= reservation_station_2[0][VJ_LOWER + 31 : VJ_LOWER];
            reservation_station_2[0][BUSY_LOWER] <= 0;

            alu2_result_reservation_station_row <= 0;
          end
    end else if (reservation_station_1[1][BUSY_LOWER] && !reservation_station_1[1][QK_LOWER + 3 : QK_LOWER] &&
        !reservation_station_1[1][QJ_LOWER + 3 : QJ_LOWER]) begin
          if (alu1_ready) begin
            alu1_Vk <= reservation_station_1[1][VK_LOWER + 31 : VK_LOWER];
            alu1_Vj <= reservation_station_1[1][VJ_LOWER + 31 : VJ_LOWER];
            reservation_station_1[0][BUSY_LOWER] <= 0;

            alu1_result_reservation_station_row <= 1;
          end else if (alu2_ready) begin
            alu2_Vk <= reservation_station_2[1][VK_LOWER + 31 : VK_LOWER];
            alu2_Vj <= reservation_station_2[1][VJ_LOWER + 31 : VJ_LOWER];
            //TODO: Copy paste changes to all branches of if/else if
          end
    end else if (reservation_station_1[2][BUSY_LOWER] && !reservation_station_1[2][QK_LOWER + 3 : QK_LOWER] &&
        !reservation_station_1[2][QJ_LOWER + 3 : QJ_LOWER]) begin
          if (alu1_ready) begin
            alu1_Vk <= reservation_station_1[2][VK_LOWER + 31 : VK_LOWER];
            alu1_Vj <= reservation_station_1[2][VJ_LOWER + 31 : VJ_LOWER];
            //TODO: Copy paste changes to all branches of if/else if
          end else if (alu2_ready) begin
            alu2_Vk <= reservation_station_2[2][VK_LOWER + 31 : VK_LOWER];
            alu2_Vj <= reservation_station_2[2][VJ_LOWER + 31 : VJ_LOWER];
            //TODO: Copy paste changes to all branches of if/else if
          end
    end
  end

  logic [3:0] alu1_reservation_station_row;
  logic [3:0] alu2_reservation_station_row;

  alu functional_unit_alu1(
      .rval1_in(alu1_Vj),
      .rval2_in(alu1_Vk),
      .aluFunc_in(alu1_opcode),
      .data_out(alu1_result), // write to bus somehow
      .ready_out(alu1_ready)
  );

  alu functional_unit_alu2(
      .rval1_in(alu2_Vj),
      .rval2_in(alu2_Vk),
      .aluFunc_in(alu2_opcode),
      .data_out(alu2_result), // write to bus somehow
      .ready_out(alu2_ready)
  );

  logic [1:0] cdb_result_reservation_station;
  logic [2:0] cdb_result_reservation_station_row;
  logic signed [31:0] cdb_result;

  always_comb begin
    if (alu1_ready) begin
      cdb_result_reservation_station = 1;
      cdb_result_reservation_station_row = alu1_reservation_station_row;
      cdb_result = alu1_result;
    end else if (alu2_ready) begin
      //TODO: What do we do here?
    end
  end

  always_ff @(posedge clk_100mhz) begin
    if (alu1_ready || alu2_ready) begin
      for (int rs_idx = 0; rs_idx < 3; rs_idx++) begin
        for (int row_idx = 0; row_idx < 3; row_idx++) begin
          if (RS rs_idx Row row_idx Q_j == {cdb_result_reservation_station, cdb_result_reservation_station_row}) begin
            RS rs_idx Row row_idx V_j <= cdb_result;
            RS rs_idx Row row_idx Q_j <= 0; 
          end
          if (RS rs_idx Row row_idx Q_k == {cdb_result_reservation_station, cdb_result_reservation_station_row}) begin
            RS rs_idx Row row_idx V_k <= cdb_result;
            RS rs_idx Row row_idx Q_k <= 0;
          end
        end
      end
    end
  end

endmodule

`default_nettype wire
