`timescale 1ns / 1ps
`default_nettype none
typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC} IType; //9 ITypes
typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc;

module execute(
        input wire [3:0] iType,
        input wire [3:0] aluFunc,
        input wire [3:0] brFunc,
        input wire [4:0] dst,
        input wire [4:0] src1,
        input wire [4:0] src2,
        input wire [19:0] imm,

        output logic [31:0] data,
        output logic [31:0] addr,
        output logic [31:0] nextPc
    );
    always_comb begin
        if (iType == OP) begin
        end else if (iType == OPIMM) begin
        end else if (iType == BRANCH) begin
        end else if (iType == LUI) begin
        end else if (iType == JAL) begin
        end else if (iType == JALR) begin
        end else begin
        end
    end
endmodule