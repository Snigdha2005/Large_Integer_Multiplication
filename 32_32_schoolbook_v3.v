module base_multiplier #(parameter base_mult = 32)(
    input clk,
    input [base_mult-1:0] x,
    input [base_mult-1:0] y,
    output reg [2*base_mult-1:0] out
);
    always @(posedge clk) begin
        out <= x * y;
    end
endmodule


module BRAM_2_2_grp_multiplier #(parameter base_mult = 32, parameter size = 128)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] y1,
    output reg [base_mult-1:0] out,
    output reg valid_out
);
    localparam num_blocks = size / (base_mult * 2);  // number of 2-word blocks
    localparam num_steps = num_blocks * num_blocks;

    reg [base_mult-1:0] a [0:2*num_blocks-1];
    reg [base_mult-1:0] b [0:2*num_blocks-1];

    integer count = 0;
    integer a_idx = 1;
    integer b_idx = 1;

    // Input packing registers
    reg [base_mult*2-1:0] in1, in2;

    // Output from base multiplier
    wire [4*base_mult-1:0] mult_result;

    // Pipeline registers to delay shift and accumulation
    reg [31:0] shift_pipe1, shift_pipe2, shift_pipe3;
    reg [4*base_mult-1:0] mult_pipe;

    // Accumulator
    reg [2*size-1:0] final_out = 0;
    reg [2*size-1:0] final_out_latched = 0;
    reg accumulation_done = 0;

    // Instantiate multiplier
    base_multiplier #(base_mult * 2) dut (
        .clk(clk),
        .x(in1),
        .y(in2),
        .out(mult_result)
    );

    // Stage 1: Collect all 2*num_blocks elements
    always @(posedge clk) begin
        if (count < 2*num_blocks) begin
            a[count] <= x1;
            b[count] <= y1;
        end
        count <= count + 1;
    end

    // Stage 2: Feed packed inputs for multiplication
    always @(posedge clk) begin
        if(a_idx <= num_blocks && b_idx <= num_blocks) begin
            if(count % 2 == 0 && count != 0) begin
                in1 <= {a[2*(a_idx-1)+1], a[2*(a_idx-1)]};
                in2 <= {b[2*(b_idx-1)+1], b[2*(b_idx-1)]};

                shift_pipe1 <= base_mult * 2 * (a_idx + b_idx - 2);
                
                // Update indices
                if (a_idx == num_blocks) begin
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < num_blocks) begin
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end
    end

    // Stage 3: Pipeline multiplier output and shift amount
    always @(posedge clk) begin
        shift_pipe2 <= shift_pipe1;
        mult_pipe <= mult_result;
    end

    always @(posedge clk) begin
        shift_pipe3 <= shift_pipe2;
    end

    // Stage 4: Accumulate shifted product
    integer step_counter = 0;
    always @(posedge clk) begin
        if ((count % 2 == 1) && (count >= 5) && (step_counter < num_steps)) begin
            final_out <= final_out + (mult_pipe << shift_pipe3);
            step_counter <= step_counter + 1;
            $display("step counter =  %d, num_steps = %d", step_counter, num_steps);
        end else if (step_counter == num_steps) begin
            final_out_latched <= final_out;
            accumulation_done <= 1;
        end
    end

    // Stage 5: Output 32-bit chunks sequentially
    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if (accumulation_done && out_idx < 2*size) begin
            out <= final_out_latched[out_idx +: 32];
            out_idx <= out_idx + 32;
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end
endmodule

module BRAM_4_2_grp_multiplier #(parameter base_mult = 32, parameter size = 128)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] x2,
    input [base_mult-1:0] y1,
    input [base_mult-1:0] y2,
    output reg [base_mult-1:0] out,
    output reg valid_out
);
    localparam num_blocks = size / (base_mult * 2);  // number of 2-word blocks
    localparam num_steps = num_blocks * num_blocks;

    reg [base_mult-1:0] a [0:2*num_blocks-1];
    reg [base_mult-1:0] b [0:2*num_blocks-1];

    integer count = 0;
    integer a_idx = 1;
    integer b_idx = 1;

    // Input packing registers
    reg [base_mult*2-1:0] in1, in2;

    // Output from base multiplier
    wire [4*base_mult-1:0] mult_result;

    // Pipeline registers to delay shift and accumulation
    reg [31:0] shift_pipe1, shift_pipe2, shift_pipe3;
    reg [4*base_mult-1:0] mult_pipe;

    // Accumulator
    reg [2*size-1:0] final_out = 0;
    reg [2*size-1:0] final_out_latched = 0;
    reg accumulation_done = 0;

    // Instantiate multiplier
    base_multiplier #(base_mult * 2) dut (
        .clk(clk),
        .x(in1),
        .y(in2),
        .out(mult_result)
    );

    // Stage 1: Collect all 2*num_blocks elements
    always @(posedge clk) begin
        if (count < 2*num_blocks) begin
            a[count] <= x1;
            a[count+1] <= x2;
            b[count] <= y1;
            b[count+1] <= y2;
        end
        count <= count + 2;
    end

    // Stage 2: Feed packed inputs for multiplication
    always @(posedge clk) begin
        if(a_idx <= num_blocks && b_idx <= num_blocks) begin
            if(count % 2 == 0 && count != 0) begin
                in1 <= {a[2*(a_idx-1)+1], a[2*(a_idx-1)]};
                in2 <= {b[2*(b_idx-1)+1], b[2*(b_idx-1)]};

                shift_pipe1 <= base_mult * 2 * (a_idx + b_idx - 2);
                
                // Update indices
                if (a_idx == num_blocks) begin
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < num_blocks) begin
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end
    end

    // Stage 3: Pipeline multiplier output and shift amount
    always @(posedge clk) begin
        shift_pipe2 <= shift_pipe1;
        mult_pipe <= mult_result;
    end

    always @(posedge clk) begin
        shift_pipe3 <= shift_pipe2;
    end

    // Stage 4: Accumulate shifted product
    integer step_counter = 0;
    always @(posedge clk) begin
        if ((count % 2 == 0) && (count >= 8) && (step_counter < num_steps)) begin
            final_out <= final_out + (mult_pipe << shift_pipe3);
            step_counter <= step_counter + 1;
            $display("step counter =  %d, num_steps = %d", step_counter, num_steps);
        end else if (step_counter == num_steps) begin
            final_out_latched <= final_out;
            accumulation_done <= 1;
        end
    end

    // Stage 5: Output 32-bit chunks sequentially
    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if (accumulation_done && out_idx < 2*size) begin
            out <= final_out_latched[out_idx +: 32];
            out_idx <= out_idx + 32;
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end
endmodule

module BRAM_2_1_grp_multiplier #(parameter base_mult = 32, parameter size = 128)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] y1,
    output reg [base_mult-1:0] out,
    output reg valid_out
);
    localparam num_blocks = size / (base_mult);  // number of 2-word blocks
    localparam num_steps = num_blocks * num_blocks;

    reg [base_mult-1:0] a [0:num_blocks-1];
    reg [base_mult-1:0] b [0:num_blocks-1];

    integer count = 0;
    integer a_idx = 1;
    integer b_idx = 1;

    // Input packing registers
    reg [base_mult-1:0] in1, in2;

    // Output from base multiplier
    wire [2*base_mult-1:0] mult_result;

    // Pipeline registers to delay shift and accumulation
    reg [31:0] shift_pipe1, shift_pipe2, shift_pipe3;
    reg [2*base_mult-1:0] mult_pipe;

    // Accumulator
    reg [2*size-1:0] final_out = 0;
    reg [2*size-1:0] final_out_latched = 0;
    reg accumulation_done = 0;

    // Instantiate multiplier
    base_multiplier #(base_mult) dut (
        .clk(clk),
        .x(in1),
        .y(in2),
        .out(mult_result)
    );

    // Stage 1: Collect all 2*num_blocks elements
    always @(posedge clk) begin
        if (count < num_blocks) begin
            a[count] <= x1;
            b[count] <= y1;
        end
        count <= count + 1;
    end

    // Stage 2: Feed packed inputs for multiplication
    always @(posedge clk) begin
        if(a_idx <= num_blocks && b_idx <= num_blocks) begin
            if(count > 0) begin
                in1 <= a[(a_idx-1)];
                in2 <= b[(b_idx-1)];

                shift_pipe1 <= base_mult * (a_idx + b_idx - 2);
                
                // Update indices
                if (a_idx == num_blocks) begin
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < num_blocks) begin
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end
    end

    // Stage 3: Pipeline multiplier output and shift amount
    always @(posedge clk) begin
        shift_pipe2 <= shift_pipe1;
        mult_pipe <= mult_result;
    end

    always @(posedge clk) begin
        shift_pipe3 <= shift_pipe2;
    end

    // Stage 4: Accumulate shifted product
    integer step_counter = 0;
    always @(posedge clk) begin
        if ((count >= 4) && (step_counter < num_steps)) begin
            final_out <= final_out + (mult_pipe << shift_pipe3);
            step_counter <= step_counter + 1;
            $display("step counter =  %d, num_steps = %d", step_counter, num_steps);
        end else if (step_counter == num_steps) begin
            final_out_latched <= final_out;
            accumulation_done <= 1;
        end
    end

    // Stage 5: Output 32-bit chunks sequentially
    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if (accumulation_done && out_idx < 2*size) begin
            out <= final_out_latched[out_idx +: 32];
            out_idx <= out_idx + 32;
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end
endmodule

module BRAM_4_1_grp_multiplier #(parameter base_mult = 32, parameter size = 128)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] x2,
    input [base_mult-1:0] y1,
    input [base_mult-1:0] y2,
    output reg [base_mult-1:0] out,
    output reg valid_out
);
    localparam num_blocks = size / (base_mult);  // number of 2-word blocks
    localparam num_steps = num_blocks * num_blocks;

    reg [base_mult-1:0] a [0:num_blocks-1];
    reg [base_mult-1:0] b [0:num_blocks-1];

    integer count = 0;
    integer a_idx = 1;
    integer b_idx = 1;

    // Input packing registers
    reg [base_mult-1:0] in1, in2;

    // Output from base multiplier
    wire [2*base_mult-1:0] mult_result;

    // Pipeline registers to delay shift and accumulation
    reg [31:0] shift_pipe1, shift_pipe2, shift_pipe3;
    reg [2*base_mult-1:0] mult_pipe;

    // Accumulator
    reg [2*size-1:0] final_out = 0;
    reg [2*size-1:0] final_out_latched = 0;
    reg accumulation_done = 0;

    // Instantiate multiplier
    base_multiplier #(base_mult) dut (
        .clk(clk),
        .x(in1),
        .y(in2),
        .out(mult_result)
    );

    // Stage 1: Collect all 2*num_blocks elements
    always @(posedge clk) begin
        if (count < num_blocks) begin
            a[count] <= x1;
            a[count + 1] <= x2;
            b[count] <= y1;
            b[count + 1] <= y2;
        end
        count <= count + 2;
    end

    // Stage 2: Feed packed inputs for multiplication
    always @(posedge clk) begin
        if(a_idx <= num_blocks && b_idx <= num_blocks) begin
            if(count > 0) begin
                in1 <= a[(a_idx-1)];
                in2 <= b[(b_idx-1)];

                shift_pipe1 <= base_mult * (a_idx + b_idx - 2);
                
                // Update indices
                if (a_idx == num_blocks) begin
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < num_blocks) begin
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end
    end

    // Stage 3: Pipeline multiplier output and shift amount
    always @(posedge clk) begin
        shift_pipe2 <= shift_pipe1;
        mult_pipe <= mult_result;
    end

    always @(posedge clk) begin
        shift_pipe3 <= shift_pipe2;
    end

    // Stage 4: Accumulate shifted product
    integer step_counter = 0;
    always @(posedge clk) begin
        if ((count >= 8) && (step_counter < num_steps)) begin
            final_out <= final_out + (mult_pipe << shift_pipe3);
            step_counter <= step_counter + 1;
            $display("step counter =  %d, num_steps = %d", step_counter, num_steps);
        end else if (step_counter == num_steps) begin
            final_out_latched <= final_out;
            accumulation_done <= 1;
        end
    end

    // Stage 5: Output 32-bit chunks sequentially
    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if (accumulation_done && out_idx < 2*size) begin
            out <= final_out_latched[out_idx +: 32];
            out_idx <= out_idx + 32;
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end
endmodule
