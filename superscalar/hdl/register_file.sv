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
    input wire [2:0] wrob_ix_in, //rob_ix of instruction whose result is potentially written back to regfile
    
    // Issue inputs
    input wire issue_in, // goes high when we issue an instruction and NEED to set the rob_ix of rd (for instructions that don't write to reg file, it will not go high)
    input wire [2:0] rob_ix_in,
    input wire [4:0] rd_in,

    input wire flush_in, //when flush is high, do something
    input wire [4:0] flush_addrs_in [7:0], // indices in the register file that we are flushing

    output logic [31:0] rval1_out,
    output logic [31:0] rval2_out,
    output logic [2:0] rob_ix1_out,
    output logic [2:0] rob_ix2_out,
    output logic rob1_valid_out,
    output logic rob2_valid_out
  );

  logic [31:0] registers [31:0]; // right number -> number of registers; left number -> size of registers
  logic [2:0] rob_ixs [31:0];
  logic [31:0] rob_valid; // 1 = the rob is valid so the data is currently being processed; 0 = register's value is currently not being processed on

  logic [31:0] a1, a2;
  // logic [2:0] a2_robix;
  assign a1 = registers[11];
  assign a2 = registers[12];
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      for(integer i=0; i<31; i=i+1) begin
        registers[i] <= 0;
        rob_ixs[i] <= 0;
        rob_valid[i] <= 0;
      end
    end else if (flush_in) begin
      for (integer j=0; j<8; j=j+1) begin
        rob_ixs[flush_addrs_in[j]] <= 3'bx; //some value that will help for debugging for now
        // rob_ixs[i] <= 3'b0; //will set to this later
        rob_valid[flush_addrs_in[j]] <= 0;
      end 
    end else begin
      if (we_in) begin
        //writing to register
        registers[wa_in] <= wd_in;
        if (wrob_ix_in == rob_ixs[wa_in]) begin
          rob_ixs[wa_in] <= 0;
          rob_valid[wa_in] <= 0;
        end
      end
      if (issue_in) begin
        // issuing new instruction
        if (rd_in != 0) begin
          rob_ixs[rd_in] <= rob_ix_in;
          rob_valid[rd_in] <= 1;
        end
      end
    end
  end

always_comb begin
  rval1_out = registers[rs1_in];
  rval2_out = registers[rs2_in];
  rob_ix1_out = rob_ixs[rs1_in];
  rob_ix2_out = rob_ixs[rs2_in];
  rob1_valid_out = rob_valid[rs1_in];
  rob2_valid_out = rob_valid[rs2_in];
  // a2_robix = rob_ixs[12];
end


endmodule

`default_nettype wire
