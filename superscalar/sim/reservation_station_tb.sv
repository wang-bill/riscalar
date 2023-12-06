`timescale 1ns / 1ps
`default_nettype none

module reservation_station_tb(); 

    logic clk_in,
    logic rst_in,
    logic valid_input_in, // input is valid
    logic fu_busy_in, // corresponding functional unit is busy
    logic [2:0] Q_i_in, //ROB entry number (ROB has size 8)
    logic [2:0] Q_j_in,
    logic signed [31:0] V_i_in,
    logic signed [31:0] V_j_in,
    logic [2:0] rob_idx_in,
    logic [3:0] opcode_in,
    logic i_ready,
    logic j_ready,

    logic signed [31:0] rval1_out,
    logic signed [31:0] rval2_out,
    logic [3:0] opcode_out,
    logic [2:0] rob_idx_out,
    logic rs_free_for_input_out, // tells whether reservation station is ready for another input
    logic rs_output_valid_out // output from RS is valid

  reservation_station uut( 
      .clk_in(clk_in),
      .rst_in(rst_in),
      .valid_input_in(valid_input_in),
      .fu_busy_in(fu_busy_in),
      .Q_i_in(Q_i_in),
      .Q_j_in(Q_j_in),
      .V_i_in(V_i_in),
      .V_j_in(V_j_in),
      .rob_idx_in(rob_idx_in),
      .opcode_in(opcode_in),
      .i_ready(i_ready),
      .j_ready(j_ready),

      .rval1_out(rval1_out),
      .rval2_out(rval2_out),
      .opcode_out(opcode_out),
      .rob_idx_in(rob_idx_out),
      .rs_free_for_input_out(rs_free_for_input_out),
      .rs_output_valid_out(rs_output_valid_out)
  ); 

  always begin
    #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
    clk_in = !clk_in;
  end

  initial begin
  $dumpfile("reservation_station_tb.vcd"); //file to store value change dump (vcd)
  $dumpvars(0,instruction_queue_tb);

  $display("Simulation finished");
  $finish;
  end
endmodule
`default_nettype wire