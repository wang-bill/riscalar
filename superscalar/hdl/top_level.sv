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


  // ALU
  logic signed [31:0] alu_Vj, alu_Vk;
  logic signed [31:0] alu_result;
  logic [3:0] alu_opcode; // get from decode


  always_ff @(posedge clk_100mhz ) begin
    if (reservation_station_1[0][BUSY_LOWER] && !reservation_station_1[0][QK_LOWER + 3 : QK_LOWER] &&
        !reservation_station_1[0][QJ_LOWER + 3 : QJ_LOWER]) begin
          
          alu_Vk <= reservation_station_1[0][VK_LOWER + 31 : VK_LOWER];
          alu_Vj <= reservation_station_1[0][VJ_LOWER + 31 : VJ_LOWER];
          reservation_station_1[0][BUSY_LOWER] <= 0;
          
    end else if (reservation_station_1[1][BUSY_LOWER] && !reservation_station_1[1][QK_LOWER + 3 : QK_LOWER] &&
        !reservation_station_1[1][QJ_LOWER + 3 : QJ_LOWER]) begin

          alu_Vk <= reservation_station_1[1][VK_LOWER + 31 : VK_LOWER];
          alu_Vj <= reservation_station_1[1][VJ_LOWER + 31 : VJ_LOWER];

    end else if (reservation_station_1[2][BUSY_LOWER] && !reservation_station_1[2][QK_LOWER + 3 : QK_LOWER] &&
        !reservation_station_1[2][QJ_LOWER + 3 : QJ_LOWER]) begin

          alu_Vk <= reservation_station_1[2][VK_LOWER + 31 : VK_LOWER];
          alu_Vj <= reservation_station_1[2][VJ_LOWER + 31 : VJ_LOWER];

    end
  end
  alu my_alu(
      .rval1_in(alu_Vj),
      .rval2_in(alu_Vk),
      .aluFunc_in(alu_opcode),
      .data_out(alu_result) // write to bus somehow
  );




endmodule

`default_nettype wire
