`timescale 1ns / 1ps
`default_nettype none
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
`include "hdl/types.svh"

module branch_predict_tb();

  logic clk_in;
  logic btn_in;
  logic [31:0] pc;
  logic correct_branch;
  logic valid_in;

  logic result;

  branch_predict uut(
    .clk_in(clk_in),
    .rst_in(btn_in),
    .pc_in(pc),
    .correct_branch(correct_branch),
    .update_valid_in(valid_in),

    .branch_taken_out(result)
  
  );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("branch_predict.vcd");
    $dumpvars(0,branch_predict_tb);

    clk_in = 1;
    btn_in = 0;
    #10;
    btn_in = 1;
    #10;
    btn_in = 0;
    pc = 0;
    valid_in = 1;
    correct_branch = 1;

    for (int i = 0; i < 10**1; i=i+1) begin
      #10;
      $display("%d", result);
    end
    
    pc=4;
    for (int i = 0; i < 10; i=i+1) begin
      #10;
      $display("%d", result);
    end
    

    $finish;
  end
endmodule
`default_nettype wire
