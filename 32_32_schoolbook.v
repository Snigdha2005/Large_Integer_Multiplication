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

module BRAM_2_2_grp_multiplier #(parameter base_mult = 32, parameter size = 64, parameter num_base = 1)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] y1,
    output reg [2*size:0] out
);
    localparam num_blocks = size / (base_mult);
    reg [base_mult-1:0] a [0:num_blocks-1];
    reg [base_mult-1:0] b [0:num_blocks-1];
    reg [base_mult*2-1:0] in1;
    reg [base_mult*2-1:0] in2;
    reg [base_mult*2-1:0] in3;
    reg [base_mult*2-1:0] in4;
    reg [base_mult*4-1:0] out1;
    reg [base_mult*4-1:0] out2;
    reg [2*size:0] partial_out[0:num_blocks];

    int count = 0;
    int k, l;

    // genvar i;
    // generate
    //     for (i = 0; i < num_blocks - 1; i = i + 1) begin : gen_lanes
    //         base_multiplier #(base_mult * 2) dut(clk, in1, in2, out1);
    //     end
    // endgenerate
    
    base_multiplier #(base_mult * 2) dut(clk, in1, in2, out1);
    base_multiplier #(base_mult * 2) dut1(clk, in3, in4, out2);

    initial begin
        in1 = 0;
        in2 = 0;
        in3 = 0;
        in4 = 0;
        out = 0;
        // total_out = 0;
    end

    always @(posedge clk) begin
        if(count < num_blocks) begin
            a[count] <= x1;
            b[count] <= y1;
        end
        count <= count + 1;
    end

    always @(posedge clk) begin
        if (count % 2 == 0 && count != 0 && count <= num_blocks) begin
            k = count / 2;
            for(l = 1; l <= k; l = l + 1)begin
                in1 <= {a[2*(k-1)+1], a[2*(k-1)]};
                in2 <= {b[2*(l-1)+1], b[2*(l-1)]};
                partial_out[(l-1)*num_blocks/2 + k - 1] <= out1 << 2 * (k + l - 2);
                $display("k =  %d, l =  %d, idx = %d, out1 =  %d, in1 = %d, in2 = %d", k, l, (l-1)*num_blocks/2 + k - 1, out1, {a[2*(k-1)+1], a[2*(k-1)]}, {b[2*(l-1)+1], b[2*(l-1)]});
                if(k != l) begin
                    in3 <= {a[2*(l-1)+1], a[2*(l-1)]};
                    in4 <= {b[2*(k-1)+1], b[2*(k-1)]};
                    partial_out[(k-1)*num_blocks/2 + l - 1] <= out2 << 2 * (k + l - 2);
                    $display("l =  %d, k =  %d, idx = %d, out2 = %d, , in3 = %d, in4 = %d", l, k, (k-1)*num_blocks/2 + l - 1, out2, {a[2*(l-1)+1], a[2*(l-1)]}, {b[2*(k-1)+1], b[2*(k-1)]});
                end
            end
        end
    end

    always @(posedge clk)begin
        for(int i = 0; i < num_blocks; i = i + 1) begin
            out <= out + partial_out[i];
        end
    end
endmodule