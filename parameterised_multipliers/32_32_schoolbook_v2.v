module base_multiplier #(parameter base_mult = 32)(
    input clk,
    input [base_mult-1:0] x,
    input [base_mult-1:0] y,
    output reg [2*base_mult:0] out
);
    always @(posedge clk) begin
        out <= x * y;
        // $display("mult done");
    end
endmodule

module BRAM_2_1_grp_multiplier #(parameter base_mult = 32, parameter size = 128)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] y1,
    output reg [base_mult-1:0] out
);
    localparam num_blocks = size / (base_mult);
    reg [base_mult-1:0] a [0:num_blocks-1];
    reg [base_mult-1:0] b [0:num_blocks-1];
    int a_idx = 1;
    int b_idx = 1;
    int prev_a_idx = 1;
    int prev_b_idx = 1;
    reg [2*base_mult:0] partial_out [0:num_blocks*num_blocks-2];
    reg [31:0] shift_amount [0:num_blocks*num_blocks-1];
    reg [base_mult-1:0] in1;
    reg [base_mult-1:0] in2;
    reg [base_mult*2:0] out1;
    int count = 0;
    reg all_done = 0;
    reg [2*size:0] final_out;
    reg [2*size:0] outf;
    int start_idx = 0;
    reg latched = 0;

    base_multiplier #(base_mult) dut(clk, in1, in2, out1);

    always @(posedge clk) begin
        if(count < num_blocks) begin
            a[count] <= x1;
            b[count] <= y1;
        end
        count <= count + 1;
    end

    always @(posedge clk) begin
        if(a_idx <= num_blocks && b_idx <= num_blocks) begin
            if(count > 0) begin
                in1 <= a[(a_idx-1)];
                in2 <= b[(b_idx-1)];
                if (a_idx == num_blocks) begin
                    prev_a_idx <= a_idx;
                    prev_b_idx <= b_idx;
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < num_blocks) begin
                    prev_a_idx <= a_idx;
                    prev_b_idx <= b_idx;
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end
    end

    always @(posedge clk) begin
        partial_out[(prev_b_idx-1)*num_blocks + prev_a_idx - 2] <= out1;
        shift_amount[(prev_b_idx-1)*num_blocks + prev_a_idx - 1] <= base_mult * (prev_a_idx + prev_b_idx - 2);
        if(((prev_b_idx-1)*num_blocks + prev_a_idx - 1) == num_blocks*num_blocks-1) begin
            all_done <= 1;
        end 
    end

    always @(posedge clk) begin
        if (all_done)begin
            final_out = 0;
            for(int i = 0; i < num_blocks*num_blocks-1; i = i + 1)begin
                // $display("1 - final_out = %d, i = %d, partial_out = %d, shift_amount = %d", final_out, i, partial_out[i], shift_amount[i]);
                final_out = final_out + (partial_out[i] << shift_amount[i]);
                // $display("2 - final_out = %d, i = %d, partial_out = %d, shift_amount = %d, shifted_partial = %d", final_out, i, partial_out[i], shift_amount[i], partial_out[i] << shift_amount[i]);
            end
            outf <= final_out;
            latched <= 1;
        end
    end

    always @(posedge clk) begin
        if (all_done && latched && (start_idx+31) < 2*size) begin
            for (int i = 0; i < 32; i = i + 1) begin
            out[i] <= outf[start_idx + i];
            end
            start_idx <= start_idx + 32;
        end
    end
endmodule

module BRAM_4_1_grp_multiplier #(parameter base_mult = 32, parameter size = 128)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] x2,
    input [base_mult-1:0] y1,
    input [base_mult-1:0] y2,
    output reg [base_mult-1:0] out
);
    localparam num_blocks = size / (base_mult);
    reg [base_mult-1:0] a [0:num_blocks-1];
    reg [base_mult-1:0] b [0:num_blocks-1];
    int a_idx = 1;
    int b_idx = 1;
    int prev_a_idx = 1;
    int prev_b_idx = 1;
    reg [2*base_mult:0] partial_out [0:num_blocks*num_blocks-2];
    reg [31:0] shift_amount [0:num_blocks*num_blocks-1];
    reg [base_mult-1:0] in1;
    reg [base_mult-1:0] in2;
    reg [base_mult*2:0] out1;
    int count = 0;
    reg all_done = 0;
    reg [2*size:0] final_out;
    reg [2*size:0] outf;
    int start_idx = 0;
    reg latched = 0;

    base_multiplier #(base_mult) dut(clk, in1, in2, out1);

    always @(posedge clk) begin
        if(count < num_blocks) begin
            a[count] <= x1;
            a[count + 1] <= x2;
            b[count] <= y1;
            b[count + 1] <= y2;
        end
        count <= count + 2;
    end

    always @(posedge clk) begin
        if(a_idx <= num_blocks && b_idx <= num_blocks) begin
            if(count > 0) begin
                in1 <= a[(a_idx-1)];
                in2 <= b[(b_idx-1)];
                if (a_idx == num_blocks) begin
                    prev_a_idx <= a_idx;
                    prev_b_idx <= b_idx;
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < num_blocks) begin
                    prev_a_idx <= a_idx;
                    prev_b_idx <= b_idx;
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end

        if(b_idx == num_blocks + 1) begin
            prev_a_idx <= a_idx;
            prev_b_idx <= b_idx;
        end
    end

    always @(posedge clk) begin
        partial_out[(prev_b_idx-1)*num_blocks + prev_a_idx - 2] <= out1;
        shift_amount[(prev_b_idx-1)*num_blocks + prev_a_idx - 1] <= base_mult * (prev_a_idx + prev_b_idx - 2);
        if(((prev_b_idx-1)*num_blocks + prev_a_idx - 1) == num_blocks*num_blocks-1) begin
            all_done <= 1;
        end 
    end

    always @(posedge clk) begin
        if (all_done)begin
            final_out = 0;
            for(int i = 0; i < num_blocks*num_blocks-1; i = i + 1)begin
                // $display("1 - final_out = %d, i = %d, partial_out = %d, shift_amount = %d", final_out, i, partial_out[i], shift_amount[i]);
                final_out = final_out + (partial_out[i] << shift_amount[i]);
                // $display("2 - final_out = %d, i = %d, partial_out = %d, shift_amount = %d, shifted_partial = %d", final_out, i, partial_out[i], shift_amount[i], partial_out[i] << shift_amount[i]);
            end
            outf <= final_out;
            latched <= 1;
        end
    end

    always @(posedge clk) begin
        if (all_done && latched && (start_idx+31) < 2*size) begin
            for (int i = 0; i < 32; i = i + 1) begin
            out[i] <= outf[start_idx + i];
            end
            start_idx <= start_idx + 32;
        end
    end
endmodule

module BRAM_2_2_grp_multiplier #(parameter base_mult = 32, parameter size = 128)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] y1,
    output reg [base_mult-1:0] out
);
    localparam num_blocks = size / (base_mult * 2);
    reg [base_mult-1:0] a [0:2*num_blocks-1];
    reg [base_mult-1:0] b [0:2*num_blocks-1];
    int a_idx = 1;
    int b_idx = 1;
    int prev_a_idx = 1;
    int prev_b_idx = 1;
    reg [4*base_mult:0] partial_out [0:num_blocks*num_blocks-1];
    reg [31:0] shift_amount [0:num_blocks*num_blocks-1];
    // reg [4*base_mult:0] partial_out;
    // reg [31:0] shift_amount;
    reg [base_mult*2-1:0] in1;
    reg [base_mult*2-1:0] in2;
    reg [base_mult*4:0] out1;
    int count = 0;
    reg all_done = 0;
    reg [2*size:0] final_out = 0;
    reg [2*size:0] outf;
    int start_idx = 0;
    reg latched = 0;
    reg [2*size:0] next_final_out;

    base_multiplier #(base_mult * 2) dut(clk, in1, in2, out1);

    always @(posedge clk) begin
        if(count < 2 * num_blocks) begin
            a[count] <= x1;
            b[count] <= y1;
        end
        count <= count + 1;
    end

    always @(posedge clk) begin
        if(a_idx <= num_blocks && b_idx <= num_blocks) begin
            if(count % 2 == 0 && count != 0) begin
                in1 <= {a[2*(a_idx-1)+1], a[2*(a_idx-1)]};
                in2 <= {b[2*(b_idx-1)+1], b[2*(b_idx-1)]};
                if (a_idx == num_blocks) begin
                    prev_a_idx <= a_idx;
                    prev_b_idx <= b_idx;
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < num_blocks) begin
                    prev_a_idx <= a_idx;
                    prev_b_idx <= b_idx;
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end
    end

    always @(posedge clk) begin
        partial_out[(prev_b_idx-1)*num_blocks + prev_a_idx - 1] <= out1;
        shift_amount[(prev_b_idx-1)*num_blocks + prev_a_idx - 1] <= base_mult * 2 * (prev_a_idx + prev_b_idx - 2);
        if(((prev_b_idx-1)*num_blocks + prev_a_idx - 1) == num_blocks*num_blocks-1) begin
            all_done <= 1;
        end 
    end
    // always @(posedge clk) begin
    //     partial_out <= out1;
    //     shift_amount <= base_mult * 2 * (prev_a_idx + prev_b_idx - 2);
    // end
    // always @(posedge clk) begin
    //     if(((prev_b_idx-1)*num_blocks + prev_a_idx - 1) >= 0 && ((prev_b_idx-1)*num_blocks + prev_a_idx - 1) < num_blocks*num_blocks) begin
    //         next_final_out = final_out + (partial_out << shift_amount);
    //         final_out <= next_final_out;
    //     end

    //     if(((prev_b_idx-1)*num_blocks + prev_a_idx - 1) == num_blocks*num_blocks-1) begin
    //         all_done <= 1;
    //         outf <= final_out;
    //     end 
    // end

    always @(posedge clk) begin
        if (all_done)begin
            final_out = 0;
            for(int i = 0; i < num_blocks*num_blocks; i = i + 1)begin
                // $display("1 - final_out = %d, i = %d, partial_out = %d, shift_amount = %d", final_out, i, partial_out[i], shift_amount[i]);
                final_out = final_out + (partial_out[i] << shift_amount[i]);
                // $display("2 - final_out = %d, i = %d, partial_out = %d, shift_amount = %d, shifted_partial = %d", final_out, i, partial_out[i], shift_amount[i], partial_out[i] << shift_amount[i]);
            end
            outf <= final_out;
            latched <= 1;
        end
    end

    always @(posedge clk) begin
        if (all_done && latched && (start_idx+31) < 2*size) begin
            for (int i = 0; i < 32; i = i + 1) begin
            out[i] <= outf[start_idx + i];
            end
            start_idx <= start_idx + 32;
        end
    end
endmodule

module BRAM_4_2_grp_multiplier #(parameter base_mult = 32, parameter size = 128)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] x2,
    input [base_mult-1:0] y1,
    input [base_mult-1:0] y2,
    output reg [base_mult-1:0] out
);
    localparam num_blocks = size / (base_mult * 2);
    reg [base_mult-1:0] a [0:2*num_blocks-1];
    reg [base_mult-1:0] b [0:2*num_blocks-1];
    int a_idx = 1;
    int b_idx = 1;
    int prev_a_idx = 1;
    int prev_b_idx = 1;
    reg [4*base_mult:0] partial_out [0:num_blocks*num_blocks-1];
    reg [31:0] shift_amount [0:num_blocks*num_blocks-1];
    // reg [4*base_mult:0] partial_out;
    // reg [31:0] shift_amount;
    reg [base_mult*2-1:0] in1;
    reg [base_mult*2-1:0] in2;
    reg [base_mult*4:0] out1;
    int count = 0;
    reg all_done = 0;
    reg [2*size:0] final_out = 0;
    reg [2*size:0] outf;
    int start_idx = 0;
    reg latched = 0;
    reg [2*size:0] next_final_out;

    base_multiplier #(base_mult * 2) dut(clk, in1, in2, out1);

    always @(posedge clk) begin
        if(count < 2 * num_blocks) begin
            a[count] <= x1;
            a[count+1] <= x2;
            b[count] <= y1;
            b[count+1] <= y2;
        end
        count <= count + 2;
    end

    always @(posedge clk) begin
        if(a_idx <= num_blocks && b_idx <= num_blocks) begin
            if(count % 2 == 0 && count != 0) begin
                in1 <= {a[2*(a_idx-1)+1], a[2*(a_idx-1)]};
                in2 <= {b[2*(b_idx-1)+1], b[2*(b_idx-1)]};
                if (a_idx == num_blocks) begin
                    prev_a_idx <= a_idx;
                    prev_b_idx <= b_idx;
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < num_blocks) begin
                    prev_a_idx <= a_idx;
                    prev_b_idx <= b_idx;
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end
        if(b_idx == num_blocks+1) begin
            prev_a_idx <= a_idx;
            prev_b_idx <= b_idx;
        end
    end

    always @(posedge clk) begin
        partial_out[(prev_b_idx-1)*num_blocks + prev_a_idx - 2] <= out1;
        shift_amount[(prev_b_idx-1)*num_blocks + prev_a_idx - 1] <= base_mult * 2 * (prev_a_idx + prev_b_idx - 2);
        if(((prev_b_idx-1)*num_blocks + prev_a_idx - 1) == num_blocks*num_blocks) begin
            all_done <= 1;
        end 
    end

    always @(posedge clk) begin
        if (all_done)begin
            final_out = 0;
            for(int i = 0; i < num_blocks*num_blocks; i = i + 1)begin
                // $display("1 - final_out = %d, i = %d, partial_out = %d, shift_amount = %d", final_out, i, partial_out[i], shift_amount[i]);
                final_out = final_out + (partial_out[i] << shift_amount[i]);
                // $display("2 - final_out = %d, i = %d, partial_out = %d, shift_amount = %d, shifted_partial = %d", final_out, i, partial_out[i], shift_amount[i], partial_out[i] << shift_amount[i]);
            end
            outf <= final_out;
            latched <= 1;
        end
    end

    always @(posedge clk) begin
        if (all_done && latched && (start_idx+31) < 2*size) begin
            for (int i = 0; i < 32; i = i + 1) begin
            out[i] <= outf[start_idx + i];
            end
            start_idx <= start_idx + 32;
        end
    end
endmodule