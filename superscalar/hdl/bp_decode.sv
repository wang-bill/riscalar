`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"
module bp_decode 
  (
    input wire [31:0] instruction_in,
    output logic is_branch_out,
    output logic signed [31:0] imm_out
  );
  logic [6:0] opcode;
  assign opcode = instruction_in[6:0];
  always_comb begin
    // Determines if instruction is branch (B) type
    if (opcode == 7'b1100011) begin
      imm_out = {20'b0, instruction_in[31:20]};
      is_branch_out = 1;
    end else begin
      imm_out = 0;
      is_branch_out = 0;
    end
  end
endmodule
`default_nettype wire