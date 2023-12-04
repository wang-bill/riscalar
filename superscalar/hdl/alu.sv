`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
`include "hdl/types.svh"

module alu(
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire signed [31:0] rval1_in,
    input wire signed [31:0] rval2_in,
    input wire [3:0] aluFunc_in,
    input wire [2:0] rob_idx,

    output logic signed [31:0] data_out,
    output logic ready_out,
    output logic busy_out
);

    localparam STALL_DURATION = 25;
    logic [STALL_DURATION-1:0] stall;

    always_ff @(posedge clk_in) begin // artificial stall
        if (rst_in) begin
            ready_out <= 0;
            busy_out <= 0; 
        end else begin
            if (ready_in) begin
                busy_out <= 1;
                ready_out <= 0;
                stall <= 1;
            end else begin
                for (int i = 1; i < STALL_DURATION; i=i+1) begin
                    stall[i] <= stall[i-1];
                end
            end

            if (stall[STALL_DURATION-1] == 1) begin // stall is over
                ready_out <= 1;
                busy_out <= 0;
            end
        end
    end

    logic [31:0] rval1_u, rval2_u;
    assign rval1_u = rval1_in;
    assign rval2_u = rval2_in;
    always_comb begin
        case (aluFunc_in)
            Add : data_out = rval1_in + rval2_in;
            Sub : data_out = rval1_in - rval2_in;
            And : data_out = rval1_in & rval2_in;
            Or  : data_out = rval1_in | rval2_in;
            Xor : data_out = rval1_in ^ rval2_in;
            Slt : data_out = (rval1_in < rval2_in) ? 1 : 0; //is this correct, should we be treating everything as signed in other ops too?
            Sltu : data_out = (rval1_u < rval2_u) ? 1 : 0;
            Sll : data_out = (rval1_in << rval2_in);
            Srl : data_out = (rval1_in >>> rval2_in); //ignores signs
            Sra : data_out = (rval1_in >> rval2_in); //considers signs
            default : data_out = 0;
        endcase
    end
    // assign ready_out = 1'b1;
    // assign busy_out = 0'b0;
endmodule //alu

`default_nettype wire
