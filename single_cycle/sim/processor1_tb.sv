`timescale 1ns / 1ps
`default_nettype none

module processor_tb();

  logic clk_in;
  logic rst_in;
  logic [31:0] instruction;
  logic signed [31:0] data_out;
  logic [31:0] addr_out;
  logic [31:0] nextPc_out;

  processor uut
          ( .clk_100mhz(clk_in),
            .rst_in(rst_in),
            // .instruction_in(instruction),
            .data_out(data_out),
            .addr_out(addr_out),
            .nextPc_out(nextPc_out)
          );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("processor.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,processor_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    // Test #1: Adding 1 to register a1 (x11) every clock cycle, for 128 iterations
    for (int i = 0; i<128; i=i+1)begin
      // instruction = 32'h0015_8593; //addi a1, a1, 1
      $display("%d", nextPc_out);
      // $display("%d", data_out);
      #10;
    end

    
    //Reset register a1 to 0
    // 32b0000_0000_0000_0101_0000_0101_1001_0011
    // instruction = 32'h0005_0593; //addi a1, a0, 0
    #10

    //Test #2: Invalid Instruction [should just ignore/not modify system]

    //Test #3: Load/store operation

    //Test #4: Branching operation

    //Test #5: Prevent changes from being made to register x0
    for (int i = 0; i<128; i=i+1)begin
      // 32b0000_0000_0001_0000_0000_0000_0001_0011
      instruction = 32'h0010_0013; //addi 0x0, 0x0, 1
      #10;
    end

    //Test #6: Testing jump and link instructions

    //Test #7: Test load upper immediate instruction
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire
