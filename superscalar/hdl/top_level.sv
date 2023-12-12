`timescale 1ns / 1ps
`default_nettype none
`include "hdl/types.svh"

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw,
  input wire [3:0] btn,

  output logic [15:0] led,
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic signed [31:0] data_out,
  output logic [31:0] addr_out,
  output logic [31:0] nextPc_out
);
  localparam INST_DEPTH = 64;
  localparam DATA_DEPTH = 64;

  // assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1 = 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];
  //Instruction Fetch
  logic correct_branch;
  logic signed [31:0] pc_bram, pc;
  logic first, second, third;
  logic first_two_or_branch;

  assign correct_branch = 1;
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      pc <= 32'h0000_0000;
      first <= 1;
      first_two_or_branch <= 1;
    end else begin
      if (iq_ready && !(instruction_fetched == 0 && pc > 0)) begin
        if (first_two_or_branch) begin
          if (first) begin
            pc_bram <= pc;
            first <= 0;
            second <= 1;
          end else if (second) begin
            pc_bram <= pc + 4;
            second <= 0;
            third <= 1;
          end else if (third) begin
            pc_bram <= pc + 8;
            third <= 0;
            first_two_or_branch <= 0;
            first <= 1;
          end
        end else begin
          pc <= iq_valid ? (inst_fetch_is_branch && branch_taken) ? pc + inst_fetch_imm : pc + 4 : pc;
          pc_bram <= iq_valid ? pc + 8 + 4: pc_bram;
          first_two_or_branch <= inst_fetch_is_branch && branch_taken;
        end
      end
    end
  end

  assign iq_valid = !(first_two_or_branch || instruction_fetched == 32'h0000_0000);

  logic inst_fetch_is_branch;
  logic signed [31:0] inst_fetch_imm;
  
  bp_decode bp_decoder(
    .instruction_in(instruction_fetched),
    .is_branch_out(inst_fetch_is_branch),
    .imm_out(inst_fetch_imm)
  );

  logic branch_taken;
  branch_predict branch_predictor(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .pc_in(pc),
    .branch_taken_out(branch_taken)
  );

  logic [$clog2(INST_DEPTH)-1:0] effective_pc;
  assign effective_pc = pc_bram[($clog2(INST_DEPTH)-1)+2:2]; // different than pc for indexing into the BRAM

  xilinx_single_port_ram_write_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(64),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(inst.mem))           // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) inst_mem (
    .addra(effective_pc),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(instruction_fetched)      // RAM output data, width determined from RAM_WIDTH
  );

  // assign instruction_fetched = instruction;
  
  logic signed [31:0] instruction_fetched, iq_instruction_out;
  logic iq_valid;
  logic iq_output_read;
  logic iq_ready, iq_inst_available;

  instruction_queue #(.SIZE(4)) inst_queue (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_in(iq_valid),
    .output_read_in(iq_output_read),
    .instruction_in(instruction_fetched),

    .inst_available_out(iq_inst_available),
    .instruction_out(iq_instruction_out),
    .ready_out(iq_ready)
  );

  // decode
  logic [31:0] inst;
  logic[3:0] iType;
  logic[3:0] aluFunc;
  logic[2:0] brFunc;

  logic signed [31:0] imm;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;

  decode decoder(
    .instruction_in(iq_instruction_out), // from instruction queue
    .iType_out(iType),
    .aluFunc_out(aluFunc),
    .brFunc_out(brFunc),
    .imm_out(imm),
    .rs1_out(rs1),
    .rs2_out(rs2),
    .rd_out(rd)
  );

  // Writeback Stage Register Wires
  logic signed [31:0] wd;
  logic [4:0] wa;
  logic we;
  logic [2:0] wrob_ix;

  // Decode Stage Register Read Wires
  logic signed [31:0] rf_val1, rf_val2;
  logic [2:0] rob_ix1_out, rob_ix2_out;
  logic rob1_valid_out, rob2_valid_out;

  // Flush ROB Wires
  logic flush;
  // logic [7:0] flush_addrs;
  logic [4:0] flush_addrs [7:0]; // indices in the register file that we are flushing, if we are clearing fewer than 8 rob entries, we can just fill in with 0s

  // registers (part of decode)
  register_file registers(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .rs1_in(rs1),
    .rs2_in(rs2),
    .wa_in(wa),
    .we_in(we),
    .wd_in(wd),
    .wrob_ix_in(wrob_ix),
    
    .issue_in(iq_output_read && (iType == OP || iType == OPIMM || iType == LUI 
                                || iType == JAL || iType == JALR || iType == STORE 
                                || iType == LUI || iType == MUL || iType == DIV)),
    .rob_ix_in(issue_rob_ix),
    .rd_in(rd),
    
    .flush_in(flush),
    .flush_addrs_in(flush_addrs),

    .rval1_out(rf_val1), //available 1 clock cycle later
    .rval2_out(rf_val2),
    .rob_ix1_out(rob_ix1_out),
    .rob_ix2_out(rob_ix2_out),
    .rob1_valid_out(rob1_valid_out),
    .rob2_valid_out(rob2_valid_out)
  );

  // Issue instruction
  // Check if RS and ROB is ready
  logic rob_ready;
  logic [2:0] issue_rob_ix;
  logic rob_commit;
  logic [3:0] rob_commit_iType;
  logic signed [31:0] rob_commit_value;
  logic signed [31:0] rob_commit_dest;
  logic [2:0] rob_commit_ix;
  logic rs_alu_ready, rs_brAlu_ready, rs_mul_ready, rs_div_ready, rs_load_ready, rs_store_ready;
  logic rs_alu_valid_in, rs_brAlu_valid_in, rs_mul_valid_in, rs_div_valid_in, rs_load_valid_in, rs_store_valid_in;
    
  // CDB Inputs  
  logic [2:0] cdb_rob_ix_in;
  logic [31:0] cdb_value_in, cdb_dest_in;
  logic cdb_valid_in;
  logic commit_out;

  // ROB Decode Outputs - To deal with the case where we read our operands from the ROB rather than from the RF
  logic signed [31:0] decode_rob_value1;
  logic signed [31:0] decode_rob_value2;
  logic decode_rob_ready1;
  logic decode_rob_ready2;
  logic [2:0] rob_can_load;
  logic [2:0] lb_rob_arr_ix [2:0];
  logic signed [31:0] lb_dest [2:0];

  rob #(.SIZE(8)) reorder_buffer( 
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),

    .valid_in(iq_output_read && iType != NOP),
    .iType_in(iType),
    .value_in(32'hFFFF_FFFF), //might be an uneccesary input since we never know the actual value yet initially
    .dest_in(rd),
    //Issue Output
    .inst_rob_ix_out(issue_rob_ix),
    //Decode Inputs
    .decode_rob1_ix_in(rob_ix1_out),
    .decode_rob2_ix_in(rob_ix2_out),
    //CDB Inputs
    .cdb_rob_ix_in(cdb_rob_ix_in),
    .cdb_value_in(cdb_value_in),
    .cdb_dest_in(cdb_dest_in),
    .cdb_valid_in(cdb_valid_in),
    //Load Inputs
    .lb_rob_arr_ix_in(lb_rob_arr_ix),
    .lb_dest_in(lb_dest),

    // Load Outputs
    .can_load_out(rob_can_load),
    .decode_value1_out(decode_rob_value1),
    .decode_ready1_out(decode_rob_ready1),
    .decode_value2_out(decode_rob_value2),
    .decode_ready2_out(decode_rob_ready2),
    //Commit Outputs
    .iType_out(rob_commit_iType),
    .value_out(rob_commit_value),
    .dest_out(rob_commit_dest),
    .ix_out(rob_commit_ix),

    .ready_out(rob_ready),
    .commit_out(commit_out)
  );

  always_comb begin
    rs_alu_valid_in = 1'b0;
    rs_brAlu_valid_in = 1'b0;
    rs_mul_valid_in = 1'b0;
    rs_div_valid_in = 1'b0;
    rs_load_valid_in = 1'b0;
    rs_store_valid_in = 1'b0;
    if (iq_inst_available && rob_ready) begin
      if ((iType == LOAD) && rs_load_ready) begin
        rs_load_valid_in = 1'b1;
      end else if ((iType == STORE) && rs_store_ready) begin
        rs_store_valid_in = 1'b1;
      end else if ((iType == BRANCH || iType == JAL || iType == JALR) && rs_brAlu_ready) begin
        rs_brAlu_valid_in = 1'b1;
      end else if ((iType == MUL) && rs_mul_ready) begin
        rs_mul_valid_in = 1'b1;
      end else if ((iType == DIV) && rs_div_ready) begin
        rs_div_valid_in = 1'b1;
      end else if (iType == NOP) begin
      end else if (rs_alu_ready) begin
        rs_alu_valid_in = 1'b1;
      end
    end
    iq_output_read = (rs_alu_valid_in || rs_brAlu_valid_in || rs_mul_valid_in || 
                      rs_div_valid_in || rs_load_valid_in || rs_store_valid_in || iType == NOP);
  end

  // Reservation Station inputs are the reg file outputs
  logic [31:0] fu_alu_rval1, fu_alu_rval2;
  logic [3:0] fu_alu_opcode;
  logic [2:0] fu_alu_rob_ix_in, fu_alu_rob_ix_out;
  logic output_valid_alu;
  logic signed [31:0] rs_valuei;
  logic signed [31:0] rs_valuej;
  logic i_ready, j_ready;

  //Issue values from either ROB or RF
  always_comb begin
    if (rob1_valid_out) begin
      if (decode_rob_ready1) begin
        rs_valuei = decode_rob_value1;
        i_ready = 1'b1;
      end else begin
        rs_valuei = rf_val1;
        i_ready = 1'b0;
      end
    end else begin
      rs_valuei = rf_val1;
      i_ready = 1'b1;
    end

    if (iType == OPIMM) begin
      rs_valuej = imm;
      j_ready = 1'b1;
    end else begin
      if (rob2_valid_out) begin
        if (decode_rob_ready2) begin
          rs_valuej = decode_rob_value2;
          j_ready = 1'b1;
        end else begin
          rs_valuej = rf_val2;
          j_ready = 1'b0;
        end
      end else begin
        rs_valuej = rf_val2;
        j_ready = 1'b1;
      end
    end
  end 
  reservation_station rs_alu(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_input_in(rs_alu_valid_in), // get from decode
    .fu_busy_in(!fu_alu_ready), // get from fu
    .Q_i_in(rob_ix1_out), // get from decode
    .Q_j_in(rob_ix2_out), // get from decode
    .V_i_in(rs_valuei), // get from decode
    .V_j_in(rs_valuej), // get from decode
    .rob_ix_in(issue_rob_ix), // from decode
    .opcode_in(aluFunc), // decode
    .i_ready_in(i_ready), // decode
    .j_ready_in(j_ready), // decode

    .cdb_rob_ix_in(cdb_rob_ix_in),
    .cdb_value_in(cdb_value_in),
    .cdb_dest_in(cdb_dest_in),
    .cdb_valid_in(cdb_valid_in),


    .rval1_out(fu_alu_rval1),
    .rval2_out(fu_alu_rval2),
    .opcode_out(fu_alu_opcode),
    .rob_ix_out(fu_alu_rob_ix_in),
    .rs_free_for_input_out(rs_alu_ready),
    .rs_output_valid_out(output_valid_alu)
  );

  logic fu_alu_busy, fu_alu_ready, fu_alu_output_valid;
  logic signed [31:0] fu_alu_result;
  logic fu_alu_read_in;
  
  alu fu_alu(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_in(output_valid_alu),
    .read_in(fu_alu_read_in),
    .rval1_in(fu_alu_rval1),
    .rval2_in(fu_alu_rval2),
    .aluFunc_in(fu_alu_opcode),
    .rob_ix_in(fu_alu_rob_ix_in),

    .rob_ix_out(fu_alu_rob_ix_out),
    .data_out(fu_alu_result), // write to bus somehow
    .ready_out(fu_alu_ready), // ready for another input
    .valid_out(fu_alu_output_valid) // goes high for one clock cycle after output is computed
  );

  logic [31:0] fu_mul_rval1, fu_mul_rval2;
  logic [3:0] fu_mul_opcode;
  logic [2:0] fu_mul_rob_ix_in;
  logic output_valid_mul;

  reservation_station rs_mul(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_input_in(rs_mul_valid_in), // get from decode
    .fu_busy_in(!fu_mul_ready), // get from fu
    .Q_i_in(rob_ix1_out), // get from decode
    .Q_j_in(rob_ix2_out), // get from decode
    .V_i_in(rs_valuei), // get from decode
    .V_j_in(rs_valuej), // get from decode
    .rob_ix_in(issue_rob_ix), // from decode
    .opcode_in(aluFunc), // decode
    .i_ready_in(i_ready), // decode
    .j_ready_in(j_ready), // decode

    .cdb_rob_ix_in(cdb_rob_ix_in),
    .cdb_value_in(cdb_value_in),
    .cdb_dest_in(cdb_dest_in),
    .cdb_valid_in(cdb_valid_in),

    .rval1_out(fu_mul_rval1),
    .rval2_out(fu_mul_rval2),
    .opcode_out(fu_mul_opcode),
    .rob_ix_out(fu_mul_rob_ix_in),
    .rs_free_for_input_out(rs_mul_ready),
    .rs_output_valid_out(output_valid_mul)
  );

  logic fu_mul_busy, fu_mul_ready, fu_mul_output_valid;
  logic [2:0] fu_mul_rob_ix_out;
  logic signed [31:0] fu_mul_result;
  logic fu_mul_read_in;
  
  multiplier fu_mul(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_in(output_valid_mul),
    .read_in(fu_mul_read_in),
    .rval1_in(fu_mul_rval1),
    .rval2_in(fu_mul_rval2),
    .rob_ix_in(fu_mul_rob_ix_in),

    .rob_ix_out(fu_mul_rob_ix_out),
    .data_out(fu_mul_result), // write to bus somehow
    .ready_out(fu_mul_ready), // ready for another input
    .valid_out(fu_mul_output_valid) // stays high after output computed until output read
  );


  logic [31:0] lb_rval1, lb_rval2;
  logic [2:0] lb_rob_ix_in;
  logic output_valid_load;

  reservation_station rs_load(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_input_in(rs_load_valid_in), // get from decode
    .fu_busy_in(!lb_ready_out), // get from load buffer
    .Q_i_in(rob_ix1_out), // get from decode
    .Q_j_in(rob_ix2_out), // get from decode
    .V_i_in(rs_valuei), // get from decode
    .V_j_in(rs_valuej), // get from decode
    .rob_ix_in(issue_rob_ix), // from decode
    .opcode_in(aluFunc), // decode
    .i_ready_in(i_ready), // decode
    .j_ready_in(j_ready), // decode

    .cdb_rob_ix_in(cdb_rob_ix_in),
    .cdb_value_in(cdb_value_in),
    .cdb_dest_in(cdb_dest_in),
    .cdb_valid_in(cdb_valid_in),

    .rval1_out(lb_rval1),
    .rval2_out(lb_rval2),
    // .opcode_out(fu_mul_opcode),
    .rob_ix_out(lb_rob_ix_in),
    .rs_free_for_input_out(lb_ready_out),
    .rs_output_valid_out(output_valid_load)
  );

  // Address calculation
  assign lb_dest_addr_in = lb_rval1 + lb_rval2;

  // Load Buffer
  logic lb_ready_out, lb_valid_out;
  logic signed [31:0] lb_dest_addr_in, lb_dest_addr_out;

  load_buffer load_buffer(
    .clk_in(clk_in),
    .rst_in(sys_rst),
    .valid_input_in(output_valid_load),

    .dest_in(lb_dest_addr_in),
    .rob_ix_in(lb_rob_ix_in),
    .can_load_in(rob_can_load),
    .read_in(),

    .lb_dest_out(lb_dest),
    .lb_rob_arr_ix_out(lb_rob_arr_ix),

    .data_out(lb_dest_addr_out),
    .ready_out(lb_ready_out),
    .valid_out(lb_valid_out)
  );

  // Store Reservation Station
  logic [31:0] rs_store_rval1, rs_store_rval2;
  logic [3:0] rs_store_opcode;
  logic [2:0] rs_store_rob_ix;
  logic output_valid_store;
  logic cdb_busy;

  reservation_station rs_store(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_input_in(rs_store_valid_in), // get from decode
    .fu_busy_in(cdb_busy), // get from cdb
    .Q_i_in(rob_ix1_out), // get from decode
    .Q_j_in(rob_ix2_out), // get from decode
    .V_i_in(rs_valuei), // get from decode
    .V_j_in(rs_valuej), // get from decode
    .rob_ix_in(issue_rob_ix), // from decode
    .opcode_in(aluFunc), // decode
    .i_ready_in(i_ready), // decode
    .j_ready_in(j_ready), // decode

    .cdb_rob_ix_in(cdb_rob_ix_in),
    .cdb_value_in(cdb_value_in),
    .cdb_dest_in(cdb_dest_in),
    .cdb_valid_in(cdb_valid_in),

    .rval1_out(rs_store_rval1),
    .rval2_out(rs_store_rval2),
    .opcode_out(rs_store_opcode),
    .rob_ix_out(rs_store_rob_ix),
    .rs_free_for_input_out(rs_store_ready),
    .rs_output_valid_out(output_valid_store)
  );
  
  // Memory Unit
  logic memory_unit_load_output_valid, memory_unit_load_read;
  

  memory_unit data_mem(
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .valid_in(lb_valid_out), // high for 1 clock cycle
  .read_in(),
  .load_or_store_in(), //either LOAD = 0 or STORE = 1
  
  // LOAD Inputs
  .load_rob_ix_in(),
  .load_mem_addr_in(),

  // STORE Inputs
  .store_mem_addr_in(),
  .store_data_in(),

  // LOAD Outputs
  .load_rob_ix_out(),
  .load_data_out(),
  .ready_out(),
  .valid_out(memory_unit_load_output_valid) // high until output is read
  );

  //Commit Stage
  assign wd = rob_commit_value;
  assign wa = rob_commit_dest;
  assign we = commit_out;
  assign wrob_ix = rob_commit_ix;
  
  // Write to CDB
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      cdb_valid_in <= 0;
      fu_alu_read_in <= 0;
      fu_mul_read_in <= 0;
      cdb_busy <= 0;
      memory_unit_load_read <= 0;
    end else begin
      if (fu_alu_output_valid) begin
        cdb_rob_ix_in <= fu_alu_rob_ix_out;
        cdb_value_in <= fu_alu_result;
        cdb_dest_in <= 32'h0000; // destination address is not needed
        cdb_valid_in <= 1;
        fu_alu_read_in <= 1;
        fu_mul_read_in <= 0;
        cdb_busy <= 1;
        memory_unit_load_read <= 0;
      end else if (fu_mul_output_valid) begin
        cdb_rob_ix_in <= fu_mul_rob_ix_out;
        cdb_value_in <= fu_mul_result;
        cdb_dest_in <= 32'h0000;
        cdb_valid_in <= 1;
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 1;
        cdb_busy <= 1;
        memory_unit_load_read <= 0;
      end else if (memory_unit_load_output_valid) begin
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 0;
        cdb_busy <= 0;
        memory_unit_load_read <= 1;
        //Connect data memory to CDB
      end else if (output_valid_store) begin
        cdb_rob_ix_in <= rs_store_rob_ix;
        cdb_value_in <= 32'h0000;
        cdb_dest_in <= rs_store_rval1 + rs_store_rval2;
        cdb_valid_in <= 1;
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 0;
        cdb_busy <= 1;
      end else begin
        cdb_valid_in <= 0;
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 0;
        cdb_busy <= 0;
      end
    end
  end


  assign led = fu_alu_result;

endmodule

`default_nettype wire
