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
  logic [4:0] rd;
  logic [31:0] imm; // value may be different depending on instruction type

  enum {R, I, S, B, U, J} inst_types;
  inst_types inst_type;

  always_comb begin
    opcode = instruction_in[6:0];
    
    if (opcode == 7'b0110011) begin // R-type
      inst_type = R;
    end else if (opcode == 7'b0010011) begin // I-type
      inst_type = I;
    end else if (opcode == 7'b0000011) begin // I-type
      inst_type = I;
    end else if (opcode == 7'b0100011) begin // S-type
      inst_type = S;
    end else if (opcode == 7'b1100011) begin // B-type
      inst_type = B;
    end else if (opcode == 7'b1101111) begin // J-type
      inst_type = J;
    end else if (opcode == 7'b1100111) begin // I-type
      inst_type = I;
    end else if (opcode == 7'b0110111) begin // U-type
      inst_type = U;
    end else if (opcode == 7'b0010111) begin // U-type
      inst_type = U;
    end else if (opcode == 7'b1110011) begin // I-type
      inst_type = I;
    end else begin
      // invalid opcode, throw some sort of error
    end

    if (inst_type == R) begin
      funct3 = instruction_in[14:12];
      funct7 = instruction_in[31:25];
      rs1 = instruction_in[19:15];
      rs2 = instruction_in[24:20];
      rd = instruction_in[11:7];
      imm = 0;
    end else if (inst_type == I) begin
      funct3 = instruction_in[14:12];
      funct7 = 0;
      rs1 = instruction_in[19:15];
      rs2 = 0;
      rd = instruction_in[11:7];
      imm = {20'b0, instruction_in[31:20]};
    end else if (inst_type == S) begin
      funct3 = instruction_in[14:12];
      funct7 = 0;
      rs1 = instruction_in[19:15];
      rs2 = instruction_in[24:20];
      rd = 0;
      imm = {20'b0, instruction_in[31:25], instruction_in[11:7]};
    end else if (inst_type == B) begin
      funct3 = instruction_in[14:12];
      funct7 = 0;
      rs1 = instruction_in[19:15];
      rs2 = instruction_in[24:20];
      rd = 0;
      imm = {19'b0, instruction_in[31], instruction_in[30:25], instruction_in[7], instruction_in[11:8], 1'b0};
    end else if (inst_type == U) begin
      funct3 = 0;
      funct7 = 0;
      rs1 = 0;
      rs2 = 0;
      rd = instruction_in[11:7];
      imm = {instruction_in[31:12], 12'b0};
    end else if (inst_type == J) begin
      funct3 = 0;
      funct7 = 0;
      rs1 = 0;
      rs2 = 0;
      rd = instruction_in[11:7];
      imm = {11'b0, instruction_in[31], instruction_in[21:12], instruction_in[22], instruction_in[30:23], 1'b0};
    end

    
  end

endmodule

`default_nettype wire