`timescale 1ns / 1ps
`default_nettype none

module execute(
        input wire [3:0] iType_in,
        input wire [3:0] aluFunc_in,
        input wire [2:0] brFunc_in,
        
        input wire signed [31:0] imm_in,
        input wire [31:0] pc_in,
        input wire signed [31:0] rval1_in,
        input wire signed [31:0] rval2_in,

        output logic signed [31:0] data_out,
        output logic [31:0] addr_out,
        output logic [31:0] nextPc_out
    );

    logic signed [31:0] alu_rval1, alu_rval2, alu_result;
    logic [31:0] nextPc_default;
    assign nextPc_default = pc_in + 4;
    assign alu_rval1 = rval1_in;
    assign alu_rval2 = (iType_in == OPIMM) ? imm_in : rval2_in;
    
    logic branch_res;

    always_comb begin
        if (iType_in == OP || iType_in == OPIMM) begin
            data_out = alu_result;
            nextPc_out = nextPc_default;
        end else if (iType_in == BRANCH) begin
            data_out = 0;
            nextPc_out = (branch_res) ? pc_in + imm_in : nextPc_default;
        end else if (iType_in == LUI) begin
            data_out = imm_in;
            nextPc_out = nextPc_default;
        end else if (iType_in == JAL) begin
            data_out = pc_in + 4;
            nextPc_out = pc_in + imm_in;
        end else if (iType_in == JALR) begin
            data_out = pc_in + 4;
            nextPc_out = (rval1_in + imm_in) & ~32'b1;
        end else if (iType_in == STORE) begin
            data_out = rval2_in;
            nextPc_out = nextPc_default;
        end else if (iType_in == AUIPC) begin
            data_out = pc_in + imm_in;
            nextPc_out = nextPc_default;
        end else begin
            data_out = 0;
            // nextPc_out = pc;
        end
    end

    alu my_alu(
        .rval1_in(alu_rval1),
        .rval2_in(alu_rval2),
        .aluFunc_in(aluFunc_in),
        .data_out(alu_result)
    );

    branchAlu my_branchAlu(
    .rval1_in(alu_rval1),
    .rval2_in(alu_rval2),
    .brFunc_in(brFunc_in),
    .bool_out(branch_res)
    );

    assign addr_out = rval1_in + imm_in;

endmodule //execute

`default_nettype wire