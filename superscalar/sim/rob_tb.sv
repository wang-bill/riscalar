`timescale 1ns / 1ps
`default_nettype none

module rob_tb(); 
    logic clk_in;
    logic rst_in;
    logic valid_in;
    //Issue Inputs
    logic [3:0] iType_in;
    logic signed [31:0] value_in;
    logic signed [31:0] dest_in;
    //Decode Inputs
    logic [2:0] decode_rob1_ix_in;
    logic [2:0] decode_rob2_ix_in;
    //CDB Inputs
    logic [2:0] cdb_rob_ix_in;
    logic signed [31:0] cdb_value_in;
    logic signed [31:0] cdb_dest_in;
    logic cdb_valid_in;
    //Issue Output
    logic [2:0] inst_rob_ix_out;
    //Decode Outputs
    logic signed [31:0] decode_value1_out;
    logic decode_ready1_out;
    logic signed [31:0] decode_value2_out;
    logic decode_ready2_out;
    //Commit Outputs
    logic [3:0] iType_out;
    logic signed [31:0] value_out;
    logic signed [31:0] dest_out;

    logic ready_out;
    logic commit_out;

    rob #(.SIZE(8)) uut( 
        .clk_in(clk_in),
        .rst_in(rst_in),
        .valid_in(valid_in),
        
        .iType_in(iType_in),
        .value_in(value_in),
        .dest_in(dest_in),
        //Decode Inputs
        .decode_rob1_ix_in(decode_rob1_ix_in),
        .decode_rob2_ix_in(decode_rob2_ix_in),
        //CDB Inputs
        .cdb_rob_ix_in(cdb_rob_ix_in),
        .cdb_value_in(cdb_value_in),
        .cdb_dest_in(cdb_value_in),
        .cdb_valid_in(cdb_valid_in),
        //Issue Outputs
        .inst_rob_ix_out(inst_rob_ix_out),
        //Decode Outputs
        .decode_value1_out(decode_value1_out),
        .decode_ready1_out(decode_ready1_out),
        .decode_value2_out(decode_value2_out),
        .decode_ready2_out(decode_ready2_out),
        //Commit Outputs
        .iType_out(iType_out),
        .value_out(value_out),
        .dest_out(dest_out),

        .ready_out(ready_out),
        .commit_out(commit_out)
    ); 

    always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
    end

    initial begin
    $dumpfile("rob_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,rob_tb);
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10;
    cdb_valid_in = 1'b0;
    //Test #1: Try writing 9 instructions into the instruction buffer
    #10;
    for (int i=0; i<9; i=i+1) begin
      valid_in = 1'b1;
      iType_in = i;
      value_in = i;
      dest_in = i;
      $display("inst_rob_ix_out: %d\n", inst_rob_ix_out);
      #10;
    end
    #10
    //Test #2: Try writing all results from CDB to the buffer
    valid_in = 1'b0; // stop writing values to buffer
    #100
    for (int i = 0; i < 8; i=i+1) begin
      cdb_rob_ix_in = i;
      cdb_dest_in = i+8;
      cdb_value_in = i+8;
      cdb_valid_in = 1'b1;
      #10;
    end
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire