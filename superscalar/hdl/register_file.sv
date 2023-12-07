`timescale 1ns / 1ps
`default_nettype none

module register_file
  (
    input wire clk_in,
    input wire rst_in,
    input wire [4:0] rs1_in,
    input wire [4:0] rs2_in,
    input wire [4:0] wa_in, // write address
    input wire we_in, // write enable, high for one clock cycle during write
    input wire [31:0] wd_in, // write data
    input wire [2:0] rob_ix_in,
    input wire rob_valid_in, // valid = 1 means the reg value is in the rob being calculated; valid = 0 means the reg value is updated
    input wire flush_in, //when flush is high, do something
    input wire [4:0] flush_addrs_in [7:0], //addresses to flush rob_ixs for 

    output logic [31:0] rd1_out,
    output logic [31:0] rd2_out,
    output logic [2:0] rob_ix1_out,
    output logic [2:0] rob_ix2_out,
    output logic rob1_valid_out,
    output logic rob2_valid_out
  );

  logic [31:0] registers [31:0]; // right number -> number of registers; left number -> size of registers
  logic [2:0] rob_ixs [31:0];
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      for(integer i=0; i<31; i=i+1) begin
        registers[i] <= 0;
      end
    end else if (flush_in) begin
      for(integer i=0; i<8; i=i+1) begin
        rob_ixs[flush_addrs_in[i]] <= 3'bxxx;
      end
    end else if (we_in) begin
      //writing to register
      registers[wa_in] <= wd_in;
      rob_ixs[wa_in] <= rob_ix_in;
    end
  end

always_comb begin
  rd1_out = registers[rs1_in];
  rd2_out = registers[rs2_in];
  rob_ix1_out = rob_ixs[rs1_in];
  rob_ix2_out = rob_ixs[rs2_in];
end


endmodule

`default_nettype wire