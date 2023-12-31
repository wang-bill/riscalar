`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"
module decode 
  (
    input wire [31:0] instruction_in,

    output logic [3:0] iType_out,
    output logic [3:0] aluFunc_out,
    output logic [2:0] brFunc_out,

    output logic signed [31:0] imm_out,
    output logic signed [4:0] rs1_out,
    output logic signed [4:0] rs2_out,
    output logic [4:0] rd_out
  );
  // instruction type 
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic [31:0] imm; // value may be different depending on instruction type

  typedef enum {R, I, S, B, U, J, N} inst_types;
  
  inst_types inst_type;
  assign opcode = instruction_in[6:0];
  always_comb begin
    // Determines instruction type
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
      inst_type = N;
    end

    // finds funct3, funct7, rs1, rs2, rd, imm
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
     imm = instruction_in[31] ? {20'hfffff, instruction_in[31:20]} : {20'h00000, instruction_in[31:20]};
    end else if (inst_type == S) begin
     funct3 = instruction_in[14:12];
     funct7 = 0;
     rs1 = instruction_in[19:15];
     rs2 = instruction_in[24:20];
     rd = 0;
     imm = instruction_in[31] ? {20'hfffff, instruction_in[31:25], instruction_in[11:7]} : {20'h00000, instruction_in[31:25], instruction_in[11:7]};
    end else if (inst_type == B) begin
     funct3 = instruction_in[14:12];
     funct7 = 0;
     rs1 = instruction_in[19:15];
     rs2 = instruction_in[24:20];
     rd = 0;
     imm = instruction_in[31] ? {19'b1111111111111111111, instruction_in[31], instruction_in[30:25], instruction_in[7], instruction_in[11:8], 1'b0} : {19'b0, instruction_in[31], instruction_in[30:25], instruction_in[7], instruction_in[11:8], 1'b0};
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
     imm = instruction_in[31] ? {11'b11111111111, instruction_in[31], instruction_in[21:12], instruction_in[22], instruction_in[30:23], 1'b0} : {11'b0, instruction_in[31], instruction_in[21:12], instruction_in[22], instruction_in[30:23], 1'b0};;
    end else begin //N type (no valid op)
      funct3 = 0;
      funct7 = 0;
      rs1 = 0;
      rs2 = 0;
      rd = 0;
      imm = 0;
    end

    imm_out = imm;
    rs1_out = rs1;
    rs2_out = rs2;
    rd_out = rd;

    // determines enum types
    if (inst_type == R) begin
      if (funct7 == 8'h01) begin // RV32M
        iType_out = (funct3 < 4) ? MUL : DIV;
        aluFunc_out = NoAlu;
      end else begin // normal
        iType_out = OP;
        if (funct3 == 4'h0 && funct7 == 8'h00) begin
          aluFunc_out = Add;
        end else if (funct3 == 4'h0 && funct7 == 8'h20) begin
          aluFunc_out = Sub;
        end else if (funct3 == 4'h4 && funct7 == 8'h00) begin
          aluFunc_out = Xor;
        end else if (funct3 == 4'h6 && funct7 == 8'h00) begin
          aluFunc_out = Or;
        end else if (funct3 == 4'h7 && funct7 == 8'h00) begin
          aluFunc_out = And;
        end else if (funct3 == 4'h1 && funct7 == 8'h00) begin
          aluFunc_out = Sll;
        end else if (funct3 == 4'h5 && funct7 == 8'h00) begin
          aluFunc_out = Srl;
        end else if (funct3 == 4'h5 && funct7 == 8'h20) begin
          aluFunc_out = Sra;
        end else if (funct3 == 4'h2 && funct7 == 8'h00) begin
          aluFunc_out = Slt;
        end else if (funct3 == 4'h3 && funct7 == 8'h00) begin
          aluFunc_out = Sltu;
        end
      end
    end else if (inst_type == I) begin
      iType_out = OPIMM;
      if (funct3 == 4'h0) begin
        aluFunc_out = Add;
      end else if (funct3 == 4'h4) begin
        aluFunc_out = Xor;
      end else if (funct3 == 4'h6) begin
        aluFunc_out = Or;
      end else if (funct3 == 4'h7) begin
        aluFunc_out = And;
      end else if (funct3 == 4'h1 && imm[11:5] == 8'h00) begin
        aluFunc_out = Sll;
      end else if (funct3 == 4'h5 && imm[11:5] == 8'h00) begin
        aluFunc_out = Srl;
      //a little unsure about this as RISC-V Manual says imm[5:11] == 0x20 (I reversed the bits)
      end else if (funct3 == 4'h5 && imm[11:5] == 8'h04) begin 
        aluFunc_out = Sra;
      end else if (funct3 == 4'h2) begin
        aluFunc_out = Slt;
      end else if (funct3 == 4'h3) begin
        aluFunc_out = Sltu;
      end
    end else begin
      aluFunc_out = NoAlu;
    end
    
    if (inst_type == B) begin
      iType_out = BRANCH;
      if (funct3 == 4'h0) begin
        brFunc_out = Eq;
      end else if (funct3 == 4'h1) begin
        brFunc_out = Neq;
      end else if (funct3 == 4'h4) begin
        brFunc_out = Lt;
      end else if (funct3 == 4'h5) begin
        brFunc_out = Ge;
      end else if (funct3 == 4'h6) begin
        brFunc_out = Ltu;
      end else if (funct3 == 4'h7) begin
        brFunc_out = Geu;
      end else begin
        brFunc_out = Dbr; // might be wrong
      end
    end else begin
      brFunc_out = Dbr;
    end

    if (inst_type == U && opcode == 7'b0110111) begin
      iType_out = LUI;
    end else if (inst_type == J) begin
      iType_out = JAL;
    end else if (inst_type == I && opcode == 7'b1100111) begin
      iType_out = JALR;
    end else if (inst_type == I && opcode == 7'b0000011) begin
      iType_out = LOAD;
    end else if (inst_type == S) begin
      iType_out = STORE;
    end else if (inst_type == U && opcode == 7'b0010111) begin
      iType_out = AUIPC;
    end else if ((inst_type != R) && (inst_type != I) && (inst_type != B)) begin
      iType_out = NOP;
    end
  end

endmodule
`default_nettype wire