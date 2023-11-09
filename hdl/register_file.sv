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

    output logic [31:0] rd1_out,
    output logic [31:0] rd2_out
  );

  logic [31:0] registers [31:0]; // right number -> number of registers; left number -> size of registers
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      for(integer i=0; i<31; i=i+1) begin
        if (i != 11) begin
          registers[i] <= 0;
        end
      end
      registers[11] <= 44; // HARD CODED a0 and a1 REGISTER FOR TESTING PURPOSES, DELETE LATER
    end else if (we_in) begin
      //writing to register
      registers[wa_in] <= wd_in;
    end
  end

always_comb begin
  rd1_out = registers[rs1_in];
  rd2_out = registers[rs2_in];
end


endmodule

`default_nettype wire