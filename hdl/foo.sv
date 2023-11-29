`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

module foo (
    input IType itype_in,
    output logic [3:0] result_out
); 
    always_comb begin
        case(itype_in) 
            OP: result_out = 1;
            OPIMM: result_out = 2;
            BRANCH: result_out = 3;
            LUI: result_out = 4;
            JAL: result_out = 5;
            JALR: result_out = 6;
            LOAD: result_out = 7;
            STORE: result_out = 8;
            AUIPC: result_out = 9;
            default: result_out = 0;
        endcase
    end
endmodule

`default_nettype wire