`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module memory_unit(
  input wire clk_in,
  input wire rst_in,
  input wire valid_in, // high for 1 clock cycle
  input wire read_in,
  input wire load_or_store_in, //either LOAD = 0 or STORE = 1
  
  // LOAD Inputs
  input wire [2:0] load_rob_ix_in,
  input wire [31:0] load_mem_addr_in,

  // STORE Inputs
  input wire [31:0] store_mem_addr_in,
  input wire signed [31:0] store_data_in,

  // LOAD Outputs
  output logic [2:0] load_rob_ix_out,
  output logic signed [31:0] load_data_out,
  output logic ready_out,
  output logic valid_out // high until output is read
);
  localparam DATA_DEPTH = 16;
  localparam LOAD_PERIOD = 3;
  logic [31:0] mem_addr;
  logic [1:0] counter;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      load_rob_ix_out <= 0;
      // mem_addr <= 0;
      counter <= 0;
    end else begin
      if (valid_in && ready_out) begin
        // mem_addr <= (load_or_store_in) ? store_mem_addr_in : load_mem_addr_in;
        load_rob_ix_out <= load_rob_ix_in;
        if (!load_or_store_in) begin
          counter <= 1;
        end
      end
      if (counter > 0 && counter < LOAD_PERIOD) begin
        counter <= counter + 1;
      end else if (counter == LOAD_PERIOD) begin
      end
      if (read_in) begin
        counter <= 0;
      end
    end
  end

  always_comb begin
    if (load_or_store_in == 0) begin
      //Load
      ready_out = (counter == 0);
      valid_out = (counter == LOAD_PERIOD) && !read_in;
    end else begin
      //Store
      ready_out = 1;
      valid_out = 0;
    end
    load_data_out = memory_output;
  end
  // data memory
  logic[$clog2(DATA_DEPTH)-1:0] effective_mem_addr;
  logic writing;
  logic signed [31:0] memory_output;

  assign mem_addr = (load_or_store_in) ? store_mem_addr_in : load_mem_addr_in;
  assign effective_mem_addr = mem_addr[($clog2(DATA_DEPTH)-1)+2:2];
  assign writing = load_or_store_in == 1 && valid_in == 1;
  xilinx_single_port_ram_write_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(DATA_DEPTH),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(data.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) data_mem (
    .addra(effective_mem_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(store_data_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(writing),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(memory_output)      // RAM output data, width determined from RAM_WIDTH
  );
endmodule

`default_nettype wire
