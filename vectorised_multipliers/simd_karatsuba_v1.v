module base_multiplier #(parameter N = 32)(input [N-1:0] x, input [N-1:0] y, output [2*N:0] out);
    assign out = x * y;
endmodule

module four_bit_mult #(parameter base_mult = 2)(
    input  [3:0] x,
    input  [3:0] y,
    output reg [8:0] out
);
    generate
        if (base_mult != 4) begin : gen_karatsuba
            wire [1:0] xl = x[1:0];
            wire [1:0] xr = x[3:2];
            wire [1:0] yl = y[1:0];
            wire [1:0] yr = y[3:2];
            wire [2:0] xsum = xl + xr;
            wire [2:0] ysum = yl + yr;

            wire [4:0] out1, out2, out3;

            base_multiplier #(2) p1(.x(xl), .y(yl), .out(out1));
            base_multiplier #(2) p2(.x(xsum[1:0]), .y(ysum[1:0]), .out(out2));
            base_multiplier #(2) p3(.x(xr), .y(yr), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 2) + (out3 << 4);
            end
        end else begin : gen_base_mult
            base_multiplier #(4) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module eight_bit_mult #(parameter base_mult = 4)(
    input  [7:0] x,
    input  [7:0] y,
    output reg [16:0] out
);
    generate
        if (base_mult != 8) begin : gen_karatsuba
            wire [3:0] xl = x[3:0];
            wire [3:0] xh = x[7:4];
            wire [3:0] yl = y[3:0];
            wire [3:0] yh = y[7:4];

            wire [4:0] xsum = xl + xh;
            wire [4:0] ysum = yl + yh;

            wire [8:0] out1, out2, out3;

            four_bit_mult p1(.x(xl), .y(yl), .out(out1));
            four_bit_mult p2(.x(xsum[3:0]), .y(ysum[3:0]), .out(out2));
            four_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 4) + (out3 << 8);
            end
        end else begin : gen_base_mult
            base_multiplier #(8) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

// // 16-bit multiplier using 8-bit Karatsuba
module sixteen_bit_mult #(parameter base_mult = 8)(
    input  [15:0] x,
    input  [15:0] y,
    output reg [32:0] out
);
    generate
        if (base_mult != 16) begin : gen_karatsuba
            wire [7:0] xl = x[7:0];
            wire [7:0] xh = x[15:8];
            wire [7:0] yl = y[7:0];
            wire [7:0] yh = y[15:8];

            wire [8:0] xsum = xl + xh;
            wire [8:0] ysum = yl + yh;

            wire [16:0] out1, out2, out3;

            eight_bit_mult p1(.x(xl), .y(yl), .out(out1));
            eight_bit_mult p2(.x(xsum[7:0]), .y(ysum[7:0]), .out(out2));
            eight_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 8) + (out3 << 16);
            end
        end else begin : gen_base_mult
            base_multiplier #(16) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule


// // 32-bit multiplier using 16-bit Karatsuba
module thirty_two_bit_mult #(parameter base_mult = 16)(
    input  [31:0] x,
    input  [31:0] y,
    output reg [64:0] out
);
    generate
        if (base_mult != 32) begin : gen_karatsuba
            wire [15:0] xl = x[15:0];
            wire [15:0] xh = x[31:16];
            wire [15:0] yl = y[15:0];
            wire [15:0] yh = y[31:16];

            wire [16:0] xsum = xl + xh;
            wire [16:0] ysum = yl + yh;

            wire [32:0] out1, out2, out3;

            sixteen_bit_mult p1(.x(xl), .y(yl), .out(out1));
            sixteen_bit_mult p2(.x(xsum[15:0]), .y(ysum[15:0]), .out(out2));
            sixteen_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 16) + (out3 << 32);
            end
        end else begin : gen_base_mult
            base_multiplier #(32) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module sixty_four_bit_mult #(parameter base_mult = 32)(
    input  [63:0] x,
    input  [63:0] y,
    output reg [128:0] out
);
    generate
        if (base_mult != 64) begin : gen_karatsuba_64
            wire [31:0] xl = x[31:0];
            wire [31:0] xh = x[63:32];
            wire [31:0] yl = y[31:0];
            wire [31:0] yh = y[63:32];

            wire [32:0] xsum = xl + xh;
            wire [32:0] ysum = yl + yh;

            wire [64:0] out1, out2, out3;

            thirty_two_bit_mult p1(.x(xl), .y(yl), .out(out1));
            thirty_two_bit_mult p2(.x(xsum[31:0]), .y(ysum[31:0]), .out(out2));
            thirty_two_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 32) + (out3 << 64);
            end
        end else begin : gen_base_mult_64
            base_multiplier #(64) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module one_twenty_eight_bit_mult #(parameter base_mult = 64)(
    input  [127:0] x,
    input  [127:0] y,
    output reg [256:0] out
);
    generate
        if (base_mult != 128) begin : gen_karatsuba_128
            wire [63:0] xl = x[63:0];
            wire [63:0] xh = x[127:64];
            wire [63:0] yl = y[63:0];
            wire [63:0] yh = y[127:64];

            wire [64:0] xsum = xl + xh;
            wire [64:0] ysum = yl + yh;

            wire [128:0] out1, out2, out3;

            sixty_four_bit_mult p1(.x(xl), .y(yl), .out(out1));
            sixty_four_bit_mult p2(.x(xsum[63:0]), .y(ysum[63:0]), .out(out2));
            sixty_four_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 64) + (out3 << 128);
            end
        end else begin : gen_base_mult_128
            base_multiplier #(128) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module two_fifty_six_bit_mult #(parameter base_mult = 128)(
    input  [255:0] x,
    input  [255:0] y,
    output reg [512:0] out
);
    generate
        if (base_mult != 256) begin : gen_karatsuba_256
            wire [127:0] xl = x[127:0];
            wire [127:0] xh = x[255:128];
            wire [127:0] yl = y[127:0];
            wire [127:0] yh = y[255:128];

            wire [128:0] xsum = xl + xh;
            wire [128:0] ysum = yl + yh;

            wire [256:0] out1, out2, out3;

            one_twenty_eight_bit_mult p1(.x(xl), .y(yl), .out(out1));
            one_twenty_eight_bit_mult p2(.x(xsum[127:0]), .y(ysum[127:0]), .out(out2));
            one_twenty_eight_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 128) + (out3 << 256);
            end
        end else begin : gen_base_mult_256
            base_multiplier #(256) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module five_twelve_bit_mult #(parameter base_mult = 256)(
    input  [511:0] x,
    input  [511:0] y,
    output reg [1024:0] out
);
    generate
        if (base_mult != 512) begin : gen_karatsuba_512
            wire [255:0] xl = x[255:0];
            wire [255:0] xh = x[511:256];
            wire [255:0] yl = y[255:0];
            wire [255:0] yh = y[511:256];

            wire [256:0] xsum = xl + xh;
            wire [256:0] ysum = yl + yh;

            wire [512:0] out1, out2, out3;

            two_fifty_six_bit_mult p1(.x(xl), .y(yl), .out(out1));
            two_fifty_six_bit_mult p2(.x(xsum[255:0]), .y(ysum[255:0]), .out(out2));
            two_fifty_six_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 256) + (out3 << 512);
            end
        end else begin : gen_base_mult_512
            base_multiplier #(512) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule
module one_zero_two_four_bit_mult #(parameter base_mult = 512)(
    input  [1023:0] x,
    input  [1023:0] y,
    output reg [2048:0] out
);
    generate
        if (base_mult != 1024) begin : gen_karatsuba_1024
            wire [511:0] xl = x[511:0];
            wire [511:0] xh = x[1023:512];
            wire [511:0] yl = y[511:0];
            wire [511:0] yh = y[1023:512];

            wire [512:0] xsum = xl + xh;
            wire [512:0] ysum = yl + yh;

            wire [1024:0] out1, out2, out3;

            five_twelve_bit_mult p1(.x(xl), .y(yl), .out(out1));
            five_twelve_bit_mult p2(.x(xsum[511:0]), .y(ysum[511:0]), .out(out2));
            five_twelve_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 512) + (out3 << 1024);
            end
        end else begin : gen_base_mult_1024
            base_multiplier #(1024) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module two_zero_four_eight_bit_mult #(parameter base_mult = 1024)(
    input  [2047:0] x,
    input  [2047:0] y,
    output reg [4096:0] out
);
    generate
        if (base_mult != 2048) begin : gen_karatsuba_2048
            wire [1023:0] xl = x[1023:0];
            wire [1023:0] xh = x[2047:1024];
            wire [1023:0] yl = y[1023:0];
            wire [1023:0] yh = y[2047:1024];

            wire [1024:0] xsum = xl + xh;
            wire [1024:0] ysum = yl + yh;

            wire [2048:0] out1, out2, out3;

            one_zero_two_four_bit_mult p1(.x(xl), .y(yl), .out(out1));
            one_zero_two_four_bit_mult p2(.x(xsum[1023:0]), .y(ysum[1023:0]), .out(out2));
            one_zero_two_four_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 1024) + (out3 << 2048);
            end
        end else begin : gen_base_mult_2048
            base_multiplier #(2048) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

// module four_zero_nine_six_bit_mult #(parameter base_mult = 32)(input [4095:0] x, input [4095:0] y, output [8192:0] out);
//     generate 
//         if (base_mult != 4096) begin
//     wire [2047:0] xl, xh, yl, yh;
//     wire [2048:0] xsum, ysum;
//     wire [4096:0] out1, out2, out3;

//     assign xl = x[2047:0];
//     assign xh = x[4095:2048];
//     assign yl = y[2047:0];
//     assign yh = y[4095:2048];

//     assign xsum = xl + xh;
//     assign ysum = yl + yh;

//     two_zero_four_eight_bit_mult p1(xl, yl, out1);
//     two_zero_four_eight_bit_mult p2(xsum[2047:0], ysum[2047:0], out2);
//     two_zero_four_eight_bit_mult p3(xh, yh, out3);

//     assign out = out1 + ((out2 - out1 - out3) << 2048) + (out3 << 4096);
//         end
//         else 
//         base_multiplier dut #(4096)(x, y, out);
//     endgenerate 
// endmodule

module four_zero_nine_six_bit_mult #(parameter base_mult = 32)(
    input  [4095:0] x,
    input  [4095:0] y,
    output reg [8192:0] out
);
    generate
        if (base_mult != 4096) begin : gen_karatsuba
            // Split inputs
            wire [2047:0] xl = x[2047:0];
            wire [2047:0] xh = x[4095:2048];
            wire [2047:0] yl = y[2047:0];
            wire [2047:0] yh = y[4095:2048];

            // Sum parts for Karatsuba middle product
            wire [2048:0] xsum = xl + xh;
            wire [2048:0] ysum = yl + yh;

            // Partial products
            wire [4096:0] out1, out2, out3;

            two_zero_four_eight_bit_mult p1(.x(xl), .y(yl), .out(out1));
            two_zero_four_eight_bit_mult p2(.x(xsum[2047:0]), .y(ysum[2047:0]), .out(out2));
            two_zero_four_eight_bit_mult p3(.x(xh), .y(yh), .out(out3));

            always @(*) begin
                out = out1 + ((out2 - out1 - out3) << 2048) + (out3 << 4096);
            end
        end else begin : gen_base_mult
            // Directly instantiate the base multiplier of size 4096 bits
            base_multiplier #(4096) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module karatsuba #(
    parameter num_single_lanes = 20,
    parameter num_bits = 4096,
    parameter base_mult = 512
)(
    input  [num_bits-1:0] x,
    input  [num_bits-1:0] y,
    output [2*num_bits:0] out
);
    generate
        if (num_bits == 4096) begin
            four_zero_nine_six_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 2048) begin
            two_zero_four_eight_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 1024) begin
            one_zero_two_four_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 512) begin
            five_twelve_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 256) begin
            two_fifty_six_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 128) begin
            one_twenty_eight_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 64) begin
            sixty_four_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 32) begin
            thirty_two_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 16) begin
            sixteen_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 8) begin
            eight_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 4) begin
            four_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 2) begin
            base_multiplier #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else begin
            base_multiplier #(num_bits) dut (.x(x), .y(y), .out(out));
        end
    endgenerate
endmodule

module vectorised_karatsuba #(parameter num_single_lanes = 14348907, parameter num_bits = 4, parameter N = 10, parameter num_lanes = 5, parameter base_mult = 512)(
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
        for (i = 0; i < N; i = i + 1) begin : gen_lanes
            karatsuba #(num_single_lanes, num_bits, base_mult) u_base (
                .x(x[i]),
                .y(y[i]),
                .out(out[i])
            );
        end
    endgenerate

    // integer batch_no, lane, idx;

    // always @(*) begin
    //     for (idx = 0; idx < N; idx = idx + 1) begin
    //         result[idx] = {2*num_bits+1{1'b0}};
    //     end

    //     for (batch_no = 0; batch_no < ((N + num_lanes - 1) / num_lanes); batch_no = batch_no + 1) begin
    //         for (lane = 0; lane < num_lanes; lane = lane + 1) begin
    //             idx = batch_no * num_lanes + lane;
    //             if (idx < N) begin
    //                 in1_reg[lane] = x[idx];
    //                 in2_reg[lane] = y[idx];
    //                 result[idx] = partial_out[lane];
    //             end else begin
    //                 in1_reg[lane] = 0;
    //                 in2_reg[lane] = 0;
    //             end
    //         end
    //     end
    // end

    // genvar j;
    // generate
    //     for (j = 0; j < N; j = j + 1) begin : assign_out
    //         assign out[j] = result[j];
    //     end
    // endgenerate

endmodule
