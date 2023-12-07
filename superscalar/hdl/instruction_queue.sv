module instruction_queue#(parameter SIZE=4)(
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire output_read_in,
    input wire [31:0] instruction_in,
    
    output logic inst_available_out,
    output logic [31:0] instruction_out,
    output logic ready_out
);
    localparam COUNTER_SIZE = $clog2(SIZE);
    logic [31:0] write_counter;
    logic [31:0] read_counter;
    logic [31:0] instruction_queue [SIZE-1:0];
    logic [31:0] instruction_queue_0;
    logic [31:0] instruction_queue_1;
    logic [31:0] instruction_queue_2;
    logic [31:0] instruction_queue_3;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            write_counter <= 0;
            read_counter <= 0;
        end else begin
            if (ready_out && valid_in) begin
                instruction_queue[write_counter[1:0]] <= instruction_in;
                write_counter <= write_counter + 1;
            end
            if (output_read_in && inst_available_out) begin
                read_counter <= read_counter + 1;
            end
        end
    end
    always_comb begin
        ready_out = (write_counter - read_counter) < SIZE;
        inst_available_out = ((write_counter - read_counter) > 0);
        instruction_out = instruction_queue[read_counter[1:0]];
        instruction_queue_0 = instruction_queue[0];
        instruction_queue_1 = instruction_queue[1];
        instruction_queue_2 = instruction_queue[2];
        instruction_queue_3 = instruction_queue[3];
    end
endmodule