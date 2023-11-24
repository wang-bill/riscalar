`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"X`"
`endif  /* ! SYNTHESIS */

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  input wire [3:0] btn,
  output logic [15:0] led,
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1 //rgb led
);

//TODO: Copy the processor.sv into this top_level and integrate together
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];

  // instruction fetch
  logic [31:0] pc;
  logic [15:0] effective_pc;
  logic wea_inst;

  logic [31:0] total_clock_cycle;

  assign effective_pc = pc[17:2]; // different than pc for indexing into the BRAM

  assign wea_inst = 0;
  logic [31:0] inst_fetched;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(2**16),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(data/inst.mem))           // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_mem (
    .addra(effective_pc),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(wea_inst),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(inst_fetched)      // RAM output data, width determined from RAM_WIDTH
  );
  localparam PULSE_PERIOD = 5;
  logic [5:0] counter;
  logic single_cycle_pulse;

  logic [31:0] final_result;
  logic one_cycle_after_done;

  logic [31:0] previous_result;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      //Simulates instruction fetch
      pc <= 32'h0000_0000; // hard coded for now
      counter <= 0;
      single_cycle_pulse <= 0;
      one_cycle_after_done <= 1;
      total_clock_cycle <= 0;
    end else begin
      if (inst_fetched != 32'h00000000) begin
        if (counter == PULSE_PERIOD-1) begin
          single_cycle_pulse <= 1;
          counter <= 1;
        end else begin // should it be initlaized to 0 or 1?
          single_cycle_pulse <= 0;
          counter <= counter + 1;
        end
        if (single_cycle_pulse) begin
          pc <= nextPc;
          previous_result <= result;
        end
      end else begin
        // led <= previous_result;
      end
    end
  end

  // decode
  logic[3:0] iType;
  logic[3:0] aluFunc;
  logic[2:0] brFunc;

  logic signed [31:0] imm;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;

  decode decoder(
    .instruction_in(inst_fetched), // fill in from fetch
    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2),
    .rd_out(rd)
  );

  // registers (part of decode)
  logic signed [31:0] rval1, rval2, wd;
  logic [4:0] wa;
  logic we;

  register_file registers(
    .clk_in(clk_100mhz),
    .pulse_in(single_cycle_pulse),
    .rst_in(sys_rst),
    .rs1_in(rs1),
    .rs2_in(rs2),
    .wa_in(wa),
    .we_in(we),
    .wd_in(wd),

    .rd1_out(rval1),
    .rd2_out(rval2)
  );

  logic signed [31:0] result;
  logic [31:0] addr, nextPc; 

  // execute
  execute execute_module(
    .iType_in(iType),
    .aluFunc_in(aluFunc),
    .brFunc_in(brFunc),
    .imm_in(imm),
    .pc_in(pc),
    .rval1_in(rval1),
    .rval2_in(rval2),

    .data_out(result),
    .addr_out(addr),
    .nextPc_out(nextPc)
  );

  // data memory
  logic[31:0] mem_addr;
  logic[15:0] effective_mem_addr;
  logic signed [31:0] mem_output;
  logic writing;

  assign mem_addr = rval1 + imm;
  assign effective_mem_addr = mem_addr[13:2];
  assign writing = (iType == STORE) ? 1 : 0;
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(2**16),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) data_mem (
    .addra(effective_mem_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(result),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(writing),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(mem_output)      // RAM output data, width determined from RAM_WIDTH
  );

  // writeback
  assign wd = (iType == LOAD) ? mem_output : result;
  assign wa = rd;
  assign we = (iType != BRANCH) && (iType != STORE) && (rd != 0);

  //Testing Output:
  // assign led = result[15:0];

  always_ff @(posedge clk_100mhz) begin
    if (inst_fetched != 32'h0000_0000) begin
      total_clock_cycle <= total_clock_cycle + 1;
    end else begin
      led <= total_clock_cycle;
    end
  end

endmodule

`default_nettype wire
