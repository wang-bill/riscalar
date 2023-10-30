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
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [19:0] imm; // value may be different depending on instruction type

  always_comb begin
    opcode = instruction_in[6:0];
    
    if (opcode == 7'b0110011) begin // R-type

    end else if (opcode == 7'b0010011) begin // I-type
    end else if (opcode == 7'b0000011) begin // I-type
    end else if (opcode == 7'b0100011) begin // S-type
    end else if (opcode == 7'b1100011) begin // B-type
    end else if (opcode == 7'b1101111) begin // J-type
    end else if (opcode == 7'b1100111) begin // I-type
    end else if (opcode == 7'b0110111) begin // U-type
    end else if (opcode == 7'b0010111) begin // U-type
    end else if (opcode == 7'b1110011) begin // I-type
    end else begin
      // invalid opcode, throw some sort of error
    end
  end

endmodule

`default_nettype wire