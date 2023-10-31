`timescale 1ns / 1ps
`default_nettype none

module decode 
  (
    input wire [31:0] instruction_in,
    input wire [31:0] pc_in,

    output Itype iType_out;
    output AluFunc aluFunc_out;
    output BrFunc brFunc_out;

    output wire signed [31:0] imm_out;
    output wire [31:0] pc_out;
    output wire signed [31:0] rval1_out;
    output wire signed [31:0] rval2_out;
  )
  // instruction type 
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic [31:0] imm; // value may be different depending on instruction type

  typedef enum {R, I, S, B, U, J} inst_types;
  
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

    pc_out = pc_in;
    imm_out = imm;
    rval1_out = rs1;
    rval2_out = rs2;
  end


  // maybe put in execute?
  typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC} IType; //9 ITypes
  typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
  typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc;

  always_comb begin
    if (inst_type == R) begin // need to change this line if we put in execute
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
        aluFunc_out = Sltu
      end
    end else if (inst_type == I && opcode == 7'b0010011) begin
      iType_out = OPIMM;
    end else if (inst_type == B) begin
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
    end else if (inst_type == U && opcode == 7'b0110111) begin
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
    end
  end

endmodule

`default_nettype wire