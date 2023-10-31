`timescale 1ns / 1ps
`default_nettype none
typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC} IType; //9 ITypes
typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc;

module execute(
        input wire [3:0] iType_in,
        input wire [3:0] aluFunc_in,
        input wire [3:0] brFunc_in,
        //input wire [4:0] dst_in,
        //input wire [4:0] src1_in, // this info is no longer relevant/not needed, I feel like we can just not include it
        //input wire [4:0] src2_in,
        
        input wire signed [31:0] imm_in,
        input wire [31:0] pc_in,
        input wire signed [31:0] rval1_in,
        input wire signed [31:0] rval2_in,

        output logic signed [31:0] data_out,
        output logic [31:0] addr_out,
        output logic [31:0] nextPc_out
    );

    logic signed [31:0] alu_rval1, alu_rval2, alu_result;
    assign alu_rval1 = rval1_in;
    assign alu_rval2 = (iType_in == OPIMM) ? imm : rval2_in;

    always_comb begin
        if (iType_in == OP || iType_in == OPIMM) begin
            data_out = alu_result;
        end else if (iType_in == LUI) begin
            data_out = imm_in;
        end else if (iType_in == JAL || iType_in == JALR) begin
            data_out = pc_in + 4;
        end else if (iType_in == STORE) begin
            data_out = rval2_in;
        end else if (iType_in == AUIPC) begin
            data_out = pc_in + imm_in;
        end else begin
            data_out = 0;
        end
    end

    alu my_alu(
        .rval1_in(alu_rval1),
        .rval2_in(alu_rval2),
        .aluFunc_in(aluFunc_in),
        .data_out(alu_result)
    );

endmodule //execute

`default_nettype wire