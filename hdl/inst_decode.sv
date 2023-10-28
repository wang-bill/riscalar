`timescale 1ns / 1ps
`default_nettype none

module instruction_decode 
  (
    input wire [31:0] instruction_in,
    
    output logic [6:0] opcode_out,
    output logic [2:0] funct3_out,
    output logic [6:0] funct7_out,
    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out,
    output logic [4:0] rd_out,
    output logic [11:0] imm_out
  )
  // instruction type 
  

endmodule

`default_nettype wire