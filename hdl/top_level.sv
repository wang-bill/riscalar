`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  input wire [3:0] btn,
  output logic [15:0] led,
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led

  input wire [31:0] instruction,
  output logic signed [31:0] data_out,
  output logic [31:0] addr_out,
  output logic [31:0] nextPc_out
);
  assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];

  // instruction fetch
  logic [31:0] pc;
  logic [31:0] inst;
  logic wea;
  logic ena;

  assign effective_pc = pc[11:0] >> 2; // take last 12 bits because depth is 4096, and divide by 4 because in reality we'd have 1 byte memory addresses
  logic [31:0] inst_fetched;
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(4096),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_mem (
    .addra(effective_pc),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(inst_fetched)      // RAM output data, width determined from RAM_WIDTH
  );

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      //Simulates instruction fetch
      inst <= inst_fetched;
      pc <= 32'h0000_0000; // hard coded for now
    end else begin
      inst <= inst_fetched;
      pc <= nextPc;
    end
  end

  // decode
  Itype iType;
  AluFunc aluFunc;
  BrFunc brFunc;
  logic signed [31:0] imm;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;

  decode(
    .clk_in(clk_100mhz),
    .instruction_in(inst), // fill in from fetch
    .pc_in(pc), // fill in from fetch

    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .pc_out(pc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2),
    .rd_out(rd)
  );

  // registers (part of decode)
  logic signed [31:0] rval1, rval2, wd;
  logic [4:0] wa;
  logic we;

  register_file(
    .clk_in(clk_100mhz),
    .rst_in(rst_in),
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
  execute(
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

  // memory
  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(4096),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_mem (
    .addra(effective_pc),     // Address bus, width determined from RAM_DEPTH
    .dina(result),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(inst_fetched)      // RAM output data, width determined from RAM_WIDTH
  );
  if (iType == LOAD) begin
    
  end 
  if (iType == STORE) begin
    
  end

  // writeback
  assign wd = result;
  assign wa = rd;
  assign we = (iType != BRANCH) && (iType != STORE);

  //Testing Output:
  assign data_out = data;
  assign addr_out = addr;
  assign nextPc_out = nextPc;
endmodule

`default_nettype wire