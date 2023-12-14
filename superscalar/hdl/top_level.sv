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
  input wire [3:0] btn,

  output logic [15:0] led,
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1 //rgb led
);
  localparam INST_DEPTH = 64;
  localparam DATA_DEPTH = 64;

  localparam ROB_SIZE = 8;
  localparam RS_DEPTH = 3;
  localparam IQ_SIZE = 4;
  localparam LOAD_BUFFER_DEPTH = 8;

  localparam ROB_IX = $clog2(ROB_SIZE)-1;
  // assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1 = 0;
  assign rgb0 = 0;

  logic sys_rst;
  assign sys_rst = btn[0];
  //Instruction Fetch
  logic correct_branch;
  logic signed [31:0] pc_bram, pc, nextPc;
  logic first, second, third;
  logic first_two_or_branch;
  logic pc_backtrack;

  assign correct_branch = !flush;
  
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      pc <= 32'h0000_0000;
      first <= 1;
      first_two_or_branch <= 1;
      pc_backtrack <= 0;
    end else begin
      if (iq_ready && !(instruction_fetched == 0 && pc > 0)) begin
        pc_backtrack <= 0;
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
          if (correct_branch) begin
            pc <= iq_valid ? (inst_fetch_is_branch && branch_taken) ? pc + inst_fetch_imm : pc + 4 : pc;
            pc_bram <= iq_valid ? pc + 8 + 4: pc_bram;
            first_two_or_branch <= (inst_fetch_is_branch && branch_taken);
          end else begin
            pc <= nextPc;
            pc_bram <= nextPc;
            first_two_or_branch <= 1;
          end
        end
      end else begin
        // if (!iq_ready && !pc_backtrack) begin
        //   pc <= pc - 4;
        //   pc_bram <= pc_bram - 12;
        //   pc_backtrack <= 1;  
        // end
      end
    end
  end

  assign iq_valid = !(first_two_or_branch || (instruction_fetched == 32'h0000_0000 && pc_bram < 8));

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
  
  logic signed [31:0] instruction_fetched, iq_instruction_out;
  logic iq_valid;
  logic iq_output_read;
  logic iq_ready, iq_inst_available;
  logic iq_instruction_branch_taken;

  instruction_queue #(.SIZE(IQ_SIZE)) inst_queue (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .valid_in(iq_valid),
    .output_read_in(iq_output_read),
    .instruction_in(instruction_fetched),
    .branch_taken_in(branch_taken),
    .flush_in(flush),

    .inst_available_out(iq_inst_available),
    .instruction_out(iq_instruction_out),
    .branch_taken_out(iq_instruction_branch_taken),
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
  logic [ROB_IX:0] wrob_ix;

  // Decode Stage Register Read Wires
  logic signed [31:0] rf_val1, rf_val2;
  logic [ROB_IX:0] rob_ix1_out, rob_ix2_out;
  logic rob1_valid_out, rob2_valid_out;

  // Flush ROB Wires
  logic flush;
  // logic [7:0] flush_addrs;
  logic [4:0] flush_addrs [7:0]; // indices in the register file that we are flushing, if we are clearing fewer than 8 rob entries, we can just fill in with 0s

  // registers (part of decode)
  register_file #(.ROB_IX(ROB_IX)) registers(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .rs1_in(rs1),
    .rs2_in(rs2),
    .wa_in(wa),
    .we_in(we),
    .wd_in(wd),
    .wrob_ix_in(wrob_ix),
    
    .issue_in(iq_output_read && (iType == OP || iType == OPIMM || iType == LUI 
                                || iType == JAL || iType == JALR || iType == STORE || iType == LOAD 
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
  logic [ROB_IX:0] issue_rob_ix;
  logic rob_commit;
  logic [3:0] rob_commit_iType;
  logic signed [31:0] rob_commit_value;
  logic signed [31:0] rob_commit_dest;
  logic [ROB_IX:0] rob_commit_ix;
  logic rs_alu_ready, rs_brAlu_ready, rs_mul_ready, rs_div_ready, rs_load_ready, rs_store_ready;
  logic rs_alu_valid_in, rs_brAlu_valid_in, rs_mul_valid_in, rs_div_valid_in, rs_load_valid_in, rs_store_valid_in;
    
  // CDB Inputs  
  logic [ROB_IX:0] cdb_rob_ix;
  logic [31:0] cdb_value, cdb_dest;
  logic cdb_valid;

  // ROB Outputs to Reg File and Data Mem
  logic commit_out, store_valid_out;

  // ROB Decode Outputs - To deal with the case where we read our operands from the ROB rather than from the RF
  logic signed [31:0] decode_rob_value1;
  logic signed [31:0] decode_rob_value2;
  logic decode_rob_ready1;
  logic decode_rob_ready2; 
  logic [ROB_IX:0] rob_can_load;
  logic [ROB_IX:0] lb_rob_arr_ix [LOAD_BUFFER_DEPTH-1:0];
  // logic [2:0] lb_rob_arr_ix0, lb_rob_arr_ix1, lb_rob_arr_ix2; 
  logic signed [31:0] lb_rob_dest [LOAD_BUFFER_DEPTH-1:0];
  // logic signed [31:0] lb_rob_dest0, lb_rob_dest1, lb_rob_dest2;
  logic store_read;

  logic signed [31:0] issue_dest;
  always_comb begin
    if (iType == BRANCH) begin
      // For branches, we always store the "back up" PC, the PC we would go to instead if we made the wrong prediction
      if (iq_instruction_branch_taken) begin
        issue_dest = pc + 4;
      end else begin
        issue_dest = pc + imm;
      end
    //temporarily store immediate in the destination if iType is STORE, else store register dest index
    end else if (iType == STORE) begin
      issue_dest = imm;
    end else begin
      issue_dest = rd;
    end
  end

  rob #(.ROB_SIZE(ROB_SIZE), .LOAD_BUFFER_DEPTH(LOAD_BUFFER_DEPTH)) reorder_buffer( 
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    //Decode Inputs
    .decode_rob1_ix_in(rob_ix1_out),
    .decode_rob2_ix_in(rob_ix2_out),

    .valid_in(iq_output_read && iType != NOP),
    .iType_in(iType),
    .value_in((iType == BRANCH) ? iq_instruction_branch_taken : 32'hFFFF_FFFF), //might be an uneccesary input since we never know the actual value yet initially
    .dest_in(issue_dest), 
    //CDB Inputs
    .cdb_rob_ix_in(cdb_rob_ix),
    .cdb_value_in(cdb_value),
    .cdb_dest_in(cdb_dest),
    .cdb_valid_in(cdb_valid),
    //Load Inputs
    .lb_rob_arr_ix_in(lb_rob_arr_ix),
    // .lb_rob_arr_ix0_in(lb_rob_arr_ix0),
    // .lb_rob_arr_ix1_in(lb_rob_arr_ix1),
    // .lb_rob_arr_ix2_in(lb_rob_arr_ix2),

    .lb_rob_arr_dest_in(lb_rob_dest),
    // .lb_rob_arr_dest0_in(lb_rob_dest0),
    // .lb_rob_arr_dest1_in(lb_rob_dest1),
    // .lb_rob_arr_dest2_in(lb_rob_dest2),
    
    // .store_read_in(store_read && ~old_store_read),
    .store_read_in(store_read),
    // Load Outputs
    .can_load_out(rob_can_load),
    .decode_value1_out(decode_rob_value1),
    .decode_ready1_out(decode_rob_ready1),
    .decode_value2_out(decode_rob_value2),
    .decode_ready2_out(decode_rob_ready2),
    //Issue Output
    .inst_rob_ix_out(issue_rob_ix),
    //Commit Outputs
    .ix_out(rob_commit_ix),
    .iType_out(rob_commit_iType),
    .value_out(rob_commit_value),
    .dest_out(rob_commit_dest),
    
    .ready_out(rob_ready),
    .commit_out(commit_out),
    .store_valid_out(store_valid_out),

    .flush_out(flush),
    .flush_addrs_out(flush_addrs),
    .nextPc_out(nextPc)
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
      end else if ((iType == OP || iType == OPIMM) && rs_alu_ready) begin
        rs_alu_valid_in = 1'b1;
      end
    end
    iq_output_read = (rs_alu_valid_in || rs_brAlu_valid_in || rs_mul_valid_in || 
                      rs_div_valid_in || rs_load_valid_in || rs_store_valid_in || iType == NOP);
  end

  // Reservation Station inputs are the reg file outputs
  logic signed [31:0] rs_valuei;
  logic signed [31:0] rs_valuej;
  logic i_ready, j_ready;

  logic [31:0] fu_alu_rval1, fu_alu_rval2;
  logic [3:0] fu_alu_opcode;
  logic [ROB_IX:0] fu_alu_rob_ix_in, fu_alu_rob_ix_out;
  logic output_valid_alu;

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

    if (iType == OPIMM || iType == LOAD) begin
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
  reservation_station #(.RS_DEPTH(RS_DEPTH), .ROB_IX(ROB_IX)) rs_alu(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .flush_in(flush),
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

    .cdb_rob_ix_in(cdb_rob_ix),
    .cdb_value_in(cdb_value),
    .cdb_dest_in(cdb_dest),
    .cdb_valid_in(cdb_valid),

    .rval1_out(fu_alu_rval1),
    .rval2_out(fu_alu_rval2),
    .opcode_out(fu_alu_opcode),
    .rob_ix_out(fu_alu_rob_ix_in),
    .rs_free_for_input_out(rs_alu_ready),
    .rs_output_valid_out(output_valid_alu)
  );

  logic fu_alu_ready, fu_alu_output_valid;
  logic signed [31:0] fu_alu_result;
  logic fu_alu_read_in;
  
  alu #(.ROB_IX(ROB_IX)) fu_alu(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .flush_in(flush),
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

  logic [31:0] fu_brAlu_rval1, fu_brAlu_rval2;
  logic [3:0] fu_brAlu_opcode;
  logic [ROB_IX:0] fu_brAlu_rob_ix_in, fu_brAlu_rob_ix_out;
  logic output_valid_brAlu;
  
  logic cdb_brAlu;
  
  reservation_station #(.RS_DEPTH(RS_DEPTH), .ROB_IX(ROB_IX)) rs_brAlu(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .flush_in(flush),
    .valid_input_in(rs_brAlu_ready), // get from decode
    .fu_busy_in(!cdb_brAlu), // get from fu
    .Q_i_in(rob_ix1_out), // get from decode
    .Q_j_in(rob_ix2_out), // get from decode
    .V_i_in(rs_valuei), // get from decode
    .V_j_in(rs_valuej), // get from decode
    .rob_ix_in(issue_rob_ix), // from decode
    .opcode_in(brFunc), // decode
    .i_ready_in(i_ready), // decode
    .j_ready_in(j_ready), // decode

    .cdb_rob_ix_in(cdb_rob_ix),
    .cdb_value_in(cdb_value),
    .cdb_dest_in(cdb_dest),
    .cdb_valid_in(cdb_valid),


    .rval1_out(fu_brAlu_rval1),
    .rval2_out(fu_brAlu_rval2),
    .opcode_out(fu_brAlu_opcode),
    .rob_ix_out(fu_brAlu_rob_ix_in),
    .rs_free_for_input_out(rs_brAlu_ready),
    .rs_output_valid_out(output_valid_brAlu)
  );

  logic fu_brAlu_result;

  // Branch ALU Functional Unit
  branchAlu #(.ROB_IX(ROB_IX)) fu_brAlu(
    .rval1_in(fu_brAlu_rval1),
    .rval2_in(fu_brAlu_rval2),
    .brFunc_in(fu_brAlu_opcode),
    .bool_out(fu_brAlu_result)
  );

  logic [31:0] fu_mul_rval1, fu_mul_rval2;
  logic [3:0] fu_mul_opcode;
  logic [ROB_IX:0] fu_mul_rob_ix_in;
  logic output_valid_mul;

  reservation_station #(.RS_DEPTH(RS_DEPTH), .ROB_IX(ROB_IX)) rs_mul(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .flush_in(flush),
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

    .cdb_rob_ix_in(cdb_rob_ix),
    .cdb_value_in(cdb_value),
    .cdb_dest_in(cdb_dest),
    .cdb_valid_in(cdb_valid),

    .rval1_out(fu_mul_rval1),
    .rval2_out(fu_mul_rval2),
    .opcode_out(fu_mul_opcode),
    .rob_ix_out(fu_mul_rob_ix_in),
    .rs_free_for_input_out(rs_mul_ready),
    .rs_output_valid_out(output_valid_mul)
  );

  logic fu_mul_busy, fu_mul_ready, fu_mul_output_valid;
  logic [ROB_IX:0] fu_mul_rob_ix_out;
  logic signed [31:0] fu_mul_result;
  logic fu_mul_read_in;
  
  multiplier #(.ROB_IX(ROB_IX)) fu_mul(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .flush_in(flush),
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
  logic [ROB_IX:0] lb_rob_ix_in;
  logic output_valid_load;

  reservation_station #(.RS_DEPTH(RS_DEPTH), .ROB_IX(ROB_IX)) rs_load(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .flush_in(flush),
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

    .cdb_rob_ix_in(cdb_rob_ix),
    .cdb_value_in(cdb_value),
    .cdb_dest_in(cdb_dest),
    .cdb_valid_in(cdb_valid),

    .rval1_out(lb_rval1),
    .rval2_out(lb_rval2),
    // .opcode_out(fu_mul_opcode),
    .rob_ix_out(lb_rob_ix_in),
    .rs_free_for_input_out(rs_load_ready),
    .rs_output_valid_out(output_valid_load)
  );

  // Address calculation
  assign lb_dest_addr_in = lb_rval1 + lb_rval2;

  // Load Buffer
  logic lb_ready_out, lb_valid_out;
  logic signed [31:0] lb_dest_addr_in, lb_dest_addr_out;
  logic lb_output_read;
  logic [ROB_IX:0] lb_rob_ix_out;

  load_buffer #(.LOAD_BUFFER_DEPTH(LOAD_BUFFER_DEPTH), .ROB_IX(ROB_IX)) load_buffer(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .flush_in(flush),
    .valid_input_in(output_valid_load),

    .dest_in(lb_dest_addr_in),
    .rob_ix_in(lb_rob_ix_in),
    .can_load_in(rob_can_load),
    // .read_in(lb_output_read && ~old_lb_output_read),
    .read_in(lb_output_read),

    .lb_dest_out(lb_rob_dest),
    // .lb_dest0_out(lb_rob_dest0),
    // .lb_dest1_out(lb_rob_dest1),
    // .lb_dest2_out(lb_rob_dest2),
    .lb_rob_arr_ix_out(lb_rob_arr_ix),
    // .lb_rob_arr_ix0_out(lb_rob_arr_ix0),
    // .lb_rob_arr_ix1_out(lb_rob_arr_ix1),
    // .lb_rob_arr_ix2_out(lb_rob_arr_ix2),

    .dest_out(lb_dest_addr_out),
    .ready_out(lb_ready_out),
    .valid_out(lb_valid_out),
    .rob_ix_out(lb_rob_ix_out)
  );

  /* This doesn't work
  assign lb_rob_dest0 = lb_rob_dest[0];
  assign lb_rob_dest1 = lb_rob_dest[1];
  assign lb_rob_dest2 = lb_rob_dest[2];
  */

  // Store Reservation Station
  logic [31:0] rs_store_rval1, rs_store_rval2;
  logic [3:0] rs_store_opcode;
  logic [ROB_IX:0] rs_store_rob_ix;
  logic output_valid_store;
  logic cdb_store;

  reservation_station #(.RS_DEPTH(RS_DEPTH), .ROB_IX(ROB_IX)) rs_store(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .flush_in(flush),
    .valid_input_in(rs_store_valid_in), // get from decode
    .fu_busy_in(cdb_store), // get from cdb
    .Q_i_in(rob_ix1_out), // get from decode
    .Q_j_in(rob_ix2_out), // get from decode
    .V_i_in(rs_valuei), // get from decode
    .V_j_in(rs_valuej), // get from decode
    .rob_ix_in(issue_rob_ix), // from decode
    .opcode_in(aluFunc), // decode
    .i_ready_in(i_ready), // decode
    .j_ready_in(j_ready), // decode

    .cdb_rob_ix_in(cdb_rob_ix),
    .cdb_value_in(cdb_value),
    .cdb_dest_in(cdb_dest),
    .cdb_valid_in(cdb_valid),

    .rval1_out(rs_store_rval1),
    .rval2_out(rs_store_rval2),
    .opcode_out(rs_store_opcode),
    .rob_ix_out(rs_store_rob_ix),
    .rs_free_for_input_out(rs_store_ready),
    .rs_output_valid_out(output_valid_store)
  );
  
  // Memory Unit
  logic memory_unit_load_output_valid, memory_unit_load_read;
  logic memory_unit_ready;

  logic [ROB_IX:0] memory_unit_load_rob_ix_out;
  logic signed [31:0] memory_unit_load_result;
  logic load_or_store;


  // Choose between load or store to Data Memory
  logic old_store_read;
  logic old_lb_output_read;
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      old_lb_output_read <= 0;
      old_store_read <= 0;
    end else if (flush) begin
      old_lb_output_read <= 0;
      old_store_read <= store_read;
    end else begin
      old_lb_output_read <= lb_output_read;
      old_store_read <= store_read;
    end
  end

  // always_ff @(posedge clk_100mhz) begin
  //   if (sys_rst) begin
  //     store_read <= 0;
  //     lb_output_read <= 0;
  //     load_or_store <= 0;
  //   end else begin
  //     if (memory_unit_ready) begin
  //       if (store_valid_out) begin
  //         store_read <= 1;
  //         lb_output_read <= 0;
  //       end else if (lb_valid_out) begin
  //         store_read <= 0;
  //         lb_output_read <= 1;
  //       end else begin
  //         store_read <= 0;
  //         lb_output_read <= 0;
  //       end 
  //     end else begin
  //       store_read <= 0;
  //       lb_output_read <= 0;
  //     end

  //     if (store_valid_out) begin
  //       load_or_store <= 1;
  //     end else begin
  //       load_or_store <= 0;
  //     end
  //   end
  // end
  always_comb begin
    store_read = memory_unit_ready && store_valid_out;
    lb_output_read = memory_unit_ready && lb_valid_out && !store_read;
    // if (memory_unit_ready) begin
    //   if (store_valid_out) begin
    //     store_read = 1;
    //     lb_output_read = 0;
    //   end else if (lb_valid_out) begin
    //     store_read = 0;
    //     lb_output_read = 1;
    //   end else begin
    //     store_read = 0;
    //     lb_output_read = 0;
    //   end 
    // end else begin
    //   store_read = 0;
    //   lb_output_read = 0;
    // end

    if (store_valid_out) begin
      load_or_store = 1;
    end else begin
      load_or_store = 0;
    end
  end

  memory_unit #(.ROB_IX(ROB_IX)) data_mem(
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .flush_in(flush),
  .valid_in(memory_unit_ready && (lb_valid_out || store_valid_out)), // high for 1 clock cycle
  .read_in(memory_unit_load_read),
  .load_or_store_in(load_or_store), //either LOAD = 0 or STORE = 1
  
  // LOAD Inputs
  .load_rob_ix_in(lb_rob_ix_out),
  .load_mem_addr_in(lb_dest_addr_out),

  // STORE Inputs
  .store_mem_addr_in(rob_commit_dest),
  .store_data_in(rob_commit_value),

  // LOAD Outputs
  .load_rob_ix_out(memory_unit_load_rob_ix_out),
  .load_data_out(memory_unit_load_result),
  .ready_out(memory_unit_ready),
  .valid_out(memory_unit_load_output_valid) // high until output is read
  );

  //Commit Stage
  assign wd = rob_commit_value;
  assign wa = rob_commit_dest;
  assign we = commit_out;
  assign wrob_ix = rob_commit_ix;
  
  // Write to CDB
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst || flush) begin
      cdb_rob_ix <= 0;
      cdb_value <= 0;
      cdb_dest <= 0;
      cdb_valid <= 0;
      fu_alu_read_in <= 0;
      fu_mul_read_in <= 0;
      cdb_store <= 0;
      memory_unit_load_read <= 0;
      cdb_brAlu <= 0;
    end else begin
      if (fu_alu_output_valid) begin
        cdb_rob_ix <= fu_alu_rob_ix_out;
        cdb_value <= fu_alu_result;
        cdb_dest <= 32'h0000; // destination address is not needed
        cdb_valid <= 1;
        fu_alu_read_in <= 1;
        fu_mul_read_in <= 0;
        cdb_store <= 1;
        memory_unit_load_read <= 0;
        cdb_brAlu <= 0;
      end else if (fu_mul_output_valid) begin
        cdb_rob_ix <= fu_mul_rob_ix_out;
        cdb_value <= fu_mul_result;
        cdb_dest <= 32'h0000;
        cdb_valid <= 1;
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 1;
        cdb_store <= 1;
        memory_unit_load_read <= 0;
        cdb_brAlu <= 0;
      end else if (memory_unit_load_output_valid) begin
        cdb_rob_ix <= memory_unit_load_rob_ix_out;
        cdb_value <= memory_unit_load_result;
        cdb_dest <= 32'h0000;
        cdb_valid <= 1;
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 0;
        cdb_store <= 0;
        memory_unit_load_read <= 1;
        cdb_brAlu <= 0;
        //Connect data memory to CDB
      end else if (output_valid_store) begin
        cdb_rob_ix <= rs_store_rob_ix;
        cdb_value <= rs_store_rval2;
        cdb_dest <= rs_store_rval1;
        cdb_valid <= 1;
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 0;
        cdb_store <= 1;
        memory_unit_load_read <= 0;
        cdb_brAlu <= 0;
      end else if (output_valid_brAlu) begin
        cdb_rob_ix <= fu_brAlu_rob_ix_in;
        cdb_value <= fu_brAlu_result;
        cdb_dest <= 32'b0000;
        cdb_valid <= 1;
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 0;
        cdb_store <= 0;
        memory_unit_load_read <= 0;
        cdb_brAlu <= 0;
      end else begin
        cdb_rob_ix <= 0;
        cdb_value <= 0;
        cdb_dest <= 0;
        cdb_valid <= 0;
        fu_alu_read_in <= 0;
        fu_mul_read_in <= 0;
        cdb_store <= 0;
        memory_unit_load_read <= 0;
        cdb_brAlu <= 0;
      end
    end
  end

  assign led = fu_alu_result;

endmodule

`default_nettype wire
