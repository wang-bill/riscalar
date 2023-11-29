`timescale 1ns / 1ps
`default_nettype none

module instruction_queue_tb(); 
    logic clk_in;
    logic rst_in;
    logic valid_in;
    logic output_read_in;
    logic [31:0] instruction_in;
    logic inst_available_out;
    logic [31:0] instruction_out;
    logic ready_out;

    instruction_queue #(.SIZE(4)) uut( 
        .clk_in(clk_in),
        .rst_in(rst_in),
        .valid_in(valid_in),
        .output_read_in(output_read_in),
        .instruction_in(instruction_in),
        .inst_available_out(inst_available_out),
        .instruction_out(instruction_out),
        .ready_out(ready_out)
    ); 

    always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
    end

    initial begin
    $dumpfile("iq_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,instruction_queue_tb);
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10;
    output_read_in = 1'b0;
    valid_in = 1'b1;
    //Test #1: Write 2 instructions into the queue, Read 2 instructions from the queue
    instruction_in = 32'hE;
    #10;
    instruction_in = 32'hF;
    #10; 
    valid_in = 1'b0;
    $display("%d", instruction_out);
    output_read_in = 1'b1;
    #10;
    $display("%d", instruction_out);
    output_read_in = 1'b1;
    #10
    output_read_in = 1'b0;
    #10
    //Test #2: Write max size 4 instructions into the queue
    valid_in = 1'b1;
    instruction_in = 32'hA;
    #10;
    instruction_in = 32'hB;
    #10; 
    instruction_in = 32'hC;
    #10;
    instruction_in = 32'hD;
    #10; 
    valid_in = 1'b0;
    #10;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire