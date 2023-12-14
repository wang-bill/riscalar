`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

// types defined in types.svh
// typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc;

module branchAlu #(parameter ROB_IX=2)(
    input wire signed [31:0] rval1_in,
    input wire signed [31:0] rval2_in,
    input wire [ROB_IX:0] brFunc_in,
    output logic bool_out
);
    logic [31:0] rval1_u, rval2_u;
    assign rval1_u = rval1_in;
    assign rval2_u = rval2_in;
    always_comb begin
        case (brFunc_in)
            Eq: bool_out = (rval1_in == rval2_in);
            Neq: bool_out = (rval1_in != rval2_in);
            Lt:  bool_out = (rval1_in < rval2_in); // Built-in signed comparison
            Ltu: bool_out = (rval1_u < rval2_u);
            Ge:  bool_out = (rval1_in >= rval2_in); // Built-in signed comparison
            Geu: bool_out = (rval1_u >= rval2_u);
            default: bool_out = 0;
        endcase
    end
endmodule //brAlu

`default_nettype wire
