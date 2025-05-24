module schoolbook_base #(parameter num_bits = 65536)(
    input [num_bits-1:0] x,
    input [num_bits-1:0] y,
    output [2*num_bits:0] out
);
    assign out = x * y;
endmodule

module schoolbook #(parameter num_bits = 65536, parameter N = 10, parameter num_lanes = 5)(
    input [num_bits-1:0] x [0:N-1],
    input [num_bits-1:0] y [0:N-1],
    output [2*num_bits:0] out [0:N-1]
);

    wire [2*num_bits:0] partial_out [0:num_lanes-1];

    reg [num_bits-1:0] in1_reg [0:num_lanes-1];
    reg [num_bits-1:0] in2_reg [0:num_lanes-1];
    reg [2*num_bits:0] result [0:N-1];

    genvar i;
    generate
        for (i = 0; i < num_lanes; i = i + 1) begin : gen_lanes
            schoolbook_base #(num_bits) u_base (
                .x(in1_reg[i]),
                .y(in2_reg[i]),
                .out(partial_out[i])
            );
        end
    endgenerate

    integer batch_no, lane, idx;


    always @(*) begin
        for (idx = 0; idx < N; idx = idx + 1) begin
            result[idx] = {2*num_bits+1{1'b0}};
        end

        for (batch_no = 0; batch_no < ((N + num_lanes - 1) / num_lanes); batch_no = batch_no + 1) begin
            for (lane = 0; lane < num_lanes; lane = lane + 1) begin
                idx = batch_no * num_lanes + lane;
                if (idx < N) begin
                    in1_reg[lane] = x[idx];
                    in2_reg[lane] = y[idx];
                    result[idx] = partial_out[lane];
                    // $display("%d, %d", result[idx], partial_out[lane]);
                end else begin
                    in1_reg[lane] = 0;
                    in2_reg[lane] = 0;
                end
            end
        end
    end

    genvar j;
    generate
        for (j = 0; j < N; j = j + 1) begin : assign_out
            assign out[j] = result[j];
        end
    endgenerate

endmodule
