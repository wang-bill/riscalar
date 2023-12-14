`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
`include "hdl/types.svh"

module alu #(parameter ROB_IX=2)(
    input wire clk_in,
    input wire rst_in,
    input wire valid_in, // high for 1 clock cycle
    input wire read_in,
    input wire signed [31:0] rval1_in,
    input wire signed [31:0] rval2_in,
    input wire [3:0] aluFunc_in,
    input wire [ROB_IX:0] rob_ix_in,

    output wire [ROB_IX:0] rob_ix_out,
    output logic signed [31:0] data_out,
    output logic ready_out,
    output logic valid_out // high until output is read
);

    localparam STALL_DURATION = 15;
    logic [STALL_DURATION-1:0] stall;
    logic stall_done;
    logic stall_can_start;


    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            ready_out <= 1;
            valid_out <= 0;
            stall_done <= 0;
            stall_can_start <= 0;
        end else begin
            if (valid_in) begin // should only hit this once
                // start computation (stall)
                stall <= 1;
                stall_done <= 0;
                stall_can_start <= 1;
                ready_out <= 0;
            end

            if (stall_can_start) begin
                if (!stall_done) begin
                    for (int i = 1; i < STALL_DURATION; i=i+1) begin
                        stall[i] <= stall[i-1];
                    end
                    if (stall[STALL_DURATION-1] == 1) begin
                        stall_done <= 1;
                    end
                end else begin
                    if (read_in) begin
                        valid_out <= 0;
                        ready_out <= 1;
                        stall_can_start <= 0;
                    end else begin
                        valid_out <= 1;
                        ready_out <= 0;
                    end
                end
            end
        end
    end

    logic [31:0] rval1_u, rval2_u;
    assign rval1_u = rval1_in;
    assign rval2_u = rval2_in;
    assign rob_ix_out = rob_ix_in;
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
