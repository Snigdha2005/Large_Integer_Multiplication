module base_multiplier #(parameter N = 32)(input [N-1:0] x, input [N-1:0] y, output reg [2*N:0] out);
    always @(*) begin
        out = x * y;
    end
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

            wire [4:0] out1, out3;

            base_multiplier #(2) p1(.x(xl), .y(yl), .out(out1));
            base_multiplier #(2) p3(.x(xr), .y(yr), .out(out3));

            // Handle sum multiplication with carry bits split
            wire [1:0] xsum_low = xsum[1:0];
            wire       xsum_carry = xsum[2];
            wire [1:0] ysum_low = ysum[1:0];
            wire       ysum_carry = ysum[2];

            wire [4:0] sumprod_low;
            wire       sumprod_carrycarry;
            wire [2:0] sumprod_carrylow1;
            wire [2:0] sumprod_carrylow2;

            base_multiplier #(2) mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            base_multiplier #(2) mult_carrylow1 (
                .x({1'b0, xsum_carry}),  // extend 1-bit to 2-bit
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            base_multiplier #(2) mult_carrylow2 (
                .x({1'b0, ysum_carry}),  // extend 1-bit to 2-bit
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [6:0] sumprod = (sumprod_carrycarry << 4) + ((sumprod_carrylow1 + sumprod_carrylow2) << 2) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 2) + (out3 << 4);
                // $display("in 4 bit ");
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

            wire [8:0] out1, out3;

            four_bit_mult p1(.x(xl), .y(yl), .out(out1));
            four_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // --- Handle sum multiplication with carry bits split ---

            wire [3:0] xsum_low = xsum[3:0];
            wire       xsum_carry = xsum[4];
            wire [3:0] ysum_low = ysum[3:0];
            wire       ysum_carry = ysum[4];

            wire [8:0] sumprod_low;
            wire       sumprod_carrycarry;
            wire [8:0] sumprod_carrylow1;
            wire [8:0] sumprod_carrylow2;

            // Low * Low (4 bits * 4 bits)
            four_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry (1 bit * 1 bit)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low (1 bit * 4 bits)
            four_bit_mult mult_carrylow1 (
                .x({3'b0, xsum_carry}),  // extend 1-bit to 4-bit
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            four_bit_mult mult_carrylow2 (
                .x({3'b0, ysum_carry}),  // extend 1-bit to 4-bit
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            // Combine all partial products:
            // sumprod = carrycarry*2^8 + (carrylow1 + carrylow2)*2^4 + low
            wire [16:0] sumprod = 
                (sumprod_carrycarry << 8) + 
                ((sumprod_carrylow1 + sumprod_carrylow2) << 4) + 
                sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 4) + (out3 << 8);
                // $display("in eigth bit karatsuba part");
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

            wire [16:0] out1, out3;

            eight_bit_mult p1(.x(xl), .y(yl), .out(out1));
            eight_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split xsum and ysum into low 8 bits + carry bit
            wire [7:0] xsum_low = xsum[7:0];
            wire       xsum_carry = xsum[8];
            wire [7:0] ysum_low = ysum[7:0];
            wire       ysum_carry = ysum[8];

            wire [16:0] sumprod_low;
            wire        sumprod_carrycarry;
            wire [16:0] sumprod_carrylow1;
            wire [16:0] sumprod_carrylow2;

            // Low * Low (8 bits * 8 bits)
            eight_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry (1 bit * 1 bit)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low (1 bit * 8 bits) - extended to 8 bits
            eight_bit_mult mult_carrylow1 (
                .x({7'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            eight_bit_mult mult_carrylow2 (
                .x({7'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            // Combine partial products:
            // sumprod = carrycarry*2^16 + (carrylow1 + carrylow2)*2^8 + low
            wire [32:0] sumprod = 
                (sumprod_carrycarry << 16) + 
                ((sumprod_carrylow1 + sumprod_carrylow2) << 8) + 
                sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 8) + (out3 << 16);
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

            wire [32:0] out1, out3;

            sixteen_bit_mult p1(.x(xl), .y(yl), .out(out1));
            sixteen_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split xsum and ysum into low 16 bits + carry bit
            wire [15:0] xsum_low = xsum[15:0];
            wire        xsum_carry = xsum[16];
            wire [15:0] ysum_low = ysum[15:0];
            wire        ysum_carry = ysum[16];

            wire [32:0] sumprod_low;
            wire        sumprod_carrycarry;
            wire [32:0] sumprod_carrylow1;
            wire [32:0] sumprod_carrylow2;

            // Low * Low (16 bits * 16 bits)
            sixteen_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry (1 bit * 1 bit)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low (1 bit * 16 bits) - extend to 16 bits by padding zeros
            sixteen_bit_mult mult_carrylow1 (
                .x({15'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            sixteen_bit_mult mult_carrylow2 (
                .x({15'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            // Combine partial products:
            // sumprod = carrycarry*2^32 + (carrylow1 + carrylow2)*2^16 + low
            wire [64:0] sumprod = 
                (sumprod_carrycarry << 32) + 
                ((sumprod_carrylow1 + sumprod_carrylow2) << 16) + 
                sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 16) + (out3 << 32);
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

            wire [64:0] out1, out3;

            thirty_two_bit_mult p1(.x(xl), .y(yl), .out(out1));
            thirty_two_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split xsum and ysum into low 32 bits + carry bit
            wire [31:0] xsum_low = xsum[31:0];
            wire        xsum_carry = xsum[32];
            wire [31:0] ysum_low = ysum[31:0];
            wire        ysum_carry = ysum[32];

            wire [64:0] sumprod_low;
            wire        sumprod_carrycarry;
            wire [64:0] sumprod_carrylow1;
            wire [64:0] sumprod_carrylow2;

            // Low * Low (32 bits * 32 bits)
            thirty_two_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry (1 bit * 1 bit)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low (1 bit * 32 bits)
            thirty_two_bit_mult mult_carrylow1 (
                .x({31'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            thirty_two_bit_mult mult_carrylow2 (
                .x({31'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            // Combine partial products:
            // sumprod = carrycarry*2^64 + (carrylow1 + carrylow2)*2^32 + low
            wire [128:0] sumprod = 
                (sumprod_carrycarry << 64) + 
                ((sumprod_carrylow1 + sumprod_carrylow2) << 32) + 
                sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 32) + (out3 << 64);
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

            wire [128:0] out1, out3;

            sixty_four_bit_mult p1(.x(xl), .y(yl), .out(out1));
            sixty_four_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split xsum and ysum into low 64 bits + carry bit
            wire [63:0] xsum_low = xsum[63:0];
            wire        xsum_carry = xsum[64];
            wire [63:0] ysum_low = ysum[63:0];
            wire        ysum_carry = ysum[64];

            wire [128:0] sumprod_low;
            wire        sumprod_carrycarry;
            wire [128:0] sumprod_carrylow1;
            wire [128:0] sumprod_carrylow2;

            // Low * Low (64 bits * 64 bits)
            sixty_four_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry (1 bit * 1 bit)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low (1 bit * 64 bits)
            sixty_four_bit_mult mult_carrylow1 (
                .x({63'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            sixty_four_bit_mult mult_carrylow2 (
                .x({63'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            // Combine partial products:
            // sumprod = carrycarry*2^128 + (carrylow1 + carrylow2)*2^64 + low
            wire [256:0] sumprod = 
                (sumprod_carrycarry << 128) + 
                ((sumprod_carrylow1 + sumprod_carrylow2) << 64) + 
                sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 64) + (out3 << 128);
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

            wire [256:0] out1, out3;

            one_twenty_eight_bit_mult p1(.x(xl), .y(yl), .out(out1));
            one_twenty_eight_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split xsum and ysum into low 128 bits and carry bit
            wire [127:0] xsum_low = xsum[127:0];
            wire         xsum_carry = xsum[128];
            wire [127:0] ysum_low = ysum[127:0];
            wire         ysum_carry = ysum[128];

            wire [256:0] sumprod_low;
            wire         sumprod_carrycarry;
            wire [256:0] sumprod_carrylow1;
            wire [256:0] sumprod_carrylow2;

            // Low * Low part
            one_twenty_eight_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry part (1-bit multiply)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low parts
            one_twenty_eight_bit_mult mult_carrylow1 (
                .x({127'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            one_twenty_eight_bit_mult mult_carrylow2 (
                .x({127'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [512:0] sumprod = (sumprod_carrycarry << 256) + ((sumprod_carrylow1 + sumprod_carrylow2) << 128) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 128) + (out3 << 256);
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

            wire [512:0] out1, out3;

            two_fifty_six_bit_mult p1(.x(xl), .y(yl), .out(out1));
            two_fifty_six_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split xsum and ysum into low 256 bits and carry bit
            wire [255:0] xsum_low = xsum[255:0];
            wire         xsum_carry = xsum[256];
            wire [255:0] ysum_low = ysum[255:0];
            wire         ysum_carry = ysum[256];

            wire [512:0] sumprod_low;
            wire         sumprod_carrycarry;
            wire [512:0] sumprod_carrylow1;
            wire [512:0] sumprod_carrylow2;

            // Low * Low part
            two_fifty_six_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry part (1-bit multiply)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low parts
            two_fifty_six_bit_mult mult_carrylow1 (
                .x({255'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            two_fifty_six_bit_mult mult_carrylow2 (
                .x({255'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [1024:0] sumprod = (sumprod_carrycarry << 512) + ((sumprod_carrylow1 + sumprod_carrylow2) << 256) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 256) + (out3 << 512);
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

            wire [1024:0] out1, out3;

            five_twelve_bit_mult p1(.x(xl), .y(yl), .out(out1));
            five_twelve_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split sums into low bits + carry
            wire [511:0] xsum_low = xsum[511:0];
            wire         xsum_carry = xsum[512];
            wire [511:0] ysum_low = ysum[511:0];
            wire         ysum_carry = ysum[512];

            wire [1024:0] sumprod_low;
            wire          sumprod_carrycarry;
            wire [1024:0] sumprod_carrylow1;
            wire [1024:0] sumprod_carrylow2;

            // Low * Low
            five_twelve_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry (1-bit multiply)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low parts
            five_twelve_bit_mult mult_carrylow1 (
                .x({511'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            five_twelve_bit_mult mult_carrylow2 (
                .x({511'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [2048:0] sumprod = (sumprod_carrycarry << 1024) + ((sumprod_carrylow1 + sumprod_carrylow2) << 512) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 512) + (out3 << 1024);
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

            wire [2048:0] out1, out3;

            one_zero_two_four_bit_mult p1(.x(xl), .y(yl), .out(out1));
            one_zero_two_four_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split sums into low bits + carry
            wire [1023:0] xsum_low = xsum[1023:0];
            wire          xsum_carry = xsum[1024];
            wire [1023:0] ysum_low = ysum[1023:0];
            wire          ysum_carry = ysum[1024];

            wire [2048:0] sumprod_low;
            wire          sumprod_carrycarry;
            wire [2048:0] sumprod_carrylow1;
            wire [2048:0] sumprod_carrylow2;

            // Low * Low
            one_zero_two_four_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry (1-bit multiply)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low parts
            one_zero_two_four_bit_mult mult_carrylow1 (
                .x({1023'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            one_zero_two_four_bit_mult mult_carrylow2 (
                .x({1023'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [4096:0] sumprod = (sumprod_carrycarry << 2048) + ((sumprod_carrylow1 + sumprod_carrylow2) << 1024) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 1024) + (out3 << 2048);
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

module four_zero_nine_six_bit_mult #(parameter base_mult = 32)(
    input  [4095:0] x,
    input  [4095:0] y,
    output reg [8192:0] out
);
    generate
        if (base_mult != 4096) begin : gen_karatsuba
            wire [2047:0] xl = x[2047:0];
            wire [2047:0] xh = x[4095:2048];
            wire [2047:0] yl = y[2047:0];
            wire [2047:0] yh = y[4095:2048];

            wire [2048:0] xsum = xl + xh;
            wire [2048:0] ysum = yl + yh;

            wire [4096:0] out1, out3;

            two_zero_four_eight_bit_mult p1(.x(xl), .y(yl), .out(out1));
            two_zero_four_eight_bit_mult p3(.x(xh), .y(yh), .out(out3));

            // Split sums into low bits + carry
            wire [2047:0] xsum_low = xsum[2047:0];
            wire          xsum_carry = xsum[2048];
            wire [2047:0] ysum_low = ysum[2047:0];
            wire          ysum_carry = ysum[2048];

            wire [4096:0] sumprod_low;
            wire          sumprod_carrycarry;
            wire [4096:0] sumprod_carrylow1;
            wire [4096:0] sumprod_carrylow2;

            // Low * Low
            two_zero_four_eight_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            // Carry * Carry (1-bit multiply)
            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            // Carry * Low parts
            two_zero_four_eight_bit_mult mult_carrylow1 (
                .x({2047'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            two_zero_four_eight_bit_mult mult_carrylow2 (
                .x({2047'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [8192:0] sumprod = (sumprod_carrycarry << 4096) + ((sumprod_carrylow1 + sumprod_carrylow2) << 2048) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 2048) + (out3 << 4096);
            end
        end else begin : gen_base_mult
            base_multiplier #(4096) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module eight_one_two_two_bit_mult #(parameter base_mult = 4096)(
    input  [8191:0] x,
    input  [8191:0] y,
    output reg [16384:0] out
);
    generate
        if (base_mult != 8192) begin : gen_karatsuba_8192
            wire [4095:0] xl = x[4095:0];
            wire [4095:0] xh = x[8191:4096];
            wire [4095:0] yl = y[4095:0];
            wire [4095:0] yh = y[8191:4096];

            wire [4096:0] xsum = xl + xh;
            wire [4096:0] ysum = yl + yh;

            wire [8192:0] out1, out3;

            four_zero_nine_six_bit_mult p1(.x(xl), .y(yl), .out(out1));
            four_zero_nine_six_bit_mult p3(.x(xh), .y(yh), .out(out3));

            wire [4095:0] xsum_low = xsum[4095:0];
            wire          xsum_carry = xsum[4096];
            wire [4095:0] ysum_low = ysum[4095:0];
            wire          ysum_carry = ysum[4096];

            wire [8192:0] sumprod_low;
            wire          sumprod_carrycarry;
            wire [8192:0] sumprod_carrylow1;
            wire [8192:0] sumprod_carrylow2;

            four_zero_nine_six_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            four_zero_nine_six_bit_mult mult_carrylow1 (
                .x({4095'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            four_zero_nine_six_bit_mult mult_carrylow2 (
                .x({4095'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [16384:0] sumprod = (sumprod_carrycarry << 8192) + ((sumprod_carrylow1 + sumprod_carrylow2) << 4096) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 4096) + (out3 << 8192);
            end
        end else begin : gen_base_mult_8192
            base_multiplier #(8192) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module sixteen_three_eight_four_bit_mult #(parameter base_mult = 8192)(
    input  [16383:0] x,
    input  [16383:0] y,
    output reg [32768:0] out
);
    generate
        if (base_mult != 16384) begin : gen_karatsuba_16384
            wire [8191:0] xl = x[8191:0];
            wire [8191:0] xh = x[16383:8192];
            wire [8191:0] yl = y[8191:0];
            wire [8191:0] yh = y[16383:8192];

            wire [8192:0] xsum = xl + xh;
            wire [8192:0] ysum = yl + yh;

            wire [16384:0] out1, out3;

            eight_one_two_two_bit_mult p1(.x(xl), .y(yl), .out(out1));
            eight_one_two_two_bit_mult p3(.x(xh), .y(yh), .out(out3));

            wire [8191:0] xsum_low = xsum[8191:0];
            wire          xsum_carry = xsum[8192];
            wire [8191:0] ysum_low = ysum[8191:0];
            wire          ysum_carry = ysum[8192];

            wire [16384:0] sumprod_low;
            wire          sumprod_carrycarry;
            wire [16384:0] sumprod_carrylow1;
            wire [16384:0] sumprod_carrylow2;

            eight_one_two_two_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            eight_one_two_two_bit_mult mult_carrylow1 (
                .x({8191'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            eight_one_two_two_bit_mult mult_carrylow2 (
                .x({8191'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [32768:0] sumprod = (sumprod_carrycarry << 16384) + ((sumprod_carrylow1 + sumprod_carrylow2) << 8192) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 8192) + (out3 << 16384);
            end
        end else begin : gen_base_mult_16384
            base_multiplier #(16384) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module thirty_two_seven_six_eight_bit_mult #(parameter base_mult = 16384)(
    input  [32767:0] x,
    input  [32767:0] y,
    output reg [65536:0] out
);
    generate
        if (base_mult != 32768) begin : gen_karatsuba_32768
            wire [16383:0] xl = x[16383:0];
            wire [16383:0] xh = x[32767:16384];
            wire [16383:0] yl = y[16383:0];
            wire [16383:0] yh = y[32767:16384];

            wire [16384:0] xsum = xl + xh;
            wire [16384:0] ysum = yl + yh;

            wire [32768:0] out1, out3;

            sixteen_three_eight_four_bit_mult p1(.x(xl), .y(yl), .out(out1));
            sixteen_three_eight_four_bit_mult p3(.x(xh), .y(yh), .out(out3));

            wire [16383:0] xsum_low = xsum[16383:0];
            wire          xsum_carry = xsum[16384];
            wire [16383:0] ysum_low = ysum[16383:0];
            wire          ysum_carry = ysum[16384];

            wire [32768:0] sumprod_low;
            wire          sumprod_carrycarry;
            wire [32768:0] sumprod_carrylow1;
            wire [32768:0] sumprod_carrylow2;

            sixteen_three_eight_four_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            sixteen_three_eight_four_bit_mult mult_carrylow1 (
                .x({16383'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            sixteen_three_eight_four_bit_mult mult_carrylow2 (
                .x({16383'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [65536:0] sumprod = (sumprod_carrycarry << 32768) + ((sumprod_carrylow1 + sumprod_carrylow2) << 16384) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 16384) + (out3 << 32768);
            end
        end else begin : gen_base_mult_32768
            base_multiplier #(32768) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module sixty_five_five_three_six_bit_mult #(parameter base_mult = 32768)(
    input  [65535:0] x,
    input  [65535:0] y,
    output reg [131072:0] out
);
    generate
        if (base_mult != 65536) begin : gen_karatsuba_65536
            wire [32767:0] xl = x[32767:0];
            wire [32767:0] xh = x[65535:32768];
            wire [32767:0] yl = y[32767:0];
            wire [32767:0] yh = y[65535:32768];

            wire [32768:0] xsum = xl + xh;
            wire [32768:0] ysum = yl + yh;

            wire [65536:0] out1, out3;

            thirty_two_seven_six_eight_bit_mult p1(.x(xl), .y(yl), .out(out1));
            thirty_two_seven_six_eight_bit_mult p3(.x(xh), .y(yh), .out(out3));

            wire [32767:0] xsum_low = xsum[32767:0];
            wire          xsum_carry = xsum[32768];
            wire [32767:0] ysum_low = ysum[32767:0];
            wire          ysum_carry = ysum[32768];

            wire [65536:0] sumprod_low;
            wire          sumprod_carrycarry;
            wire [65536:0] sumprod_carrylow1;
            wire [65536:0] sumprod_carrylow2;

            thirty_two_seven_six_eight_bit_mult mult_low (
                .x(xsum_low),
                .y(ysum_low),
                .out(sumprod_low)
            );

            base_multiplier #(1) mult_carrycarry (
                .x(xsum_carry),
                .y(ysum_carry),
                .out(sumprod_carrycarry)
            );

            thirty_two_seven_six_eight_bit_mult mult_carrylow1 (
                .x({32767'b0, xsum_carry}),
                .y(ysum_low),
                .out(sumprod_carrylow1)
            );

            thirty_two_seven_six_eight_bit_mult mult_carrylow2 (
                .x({32767'b0, ysum_carry}),
                .y(xsum_low),
                .out(sumprod_carrylow2)
            );

            wire [131072:0] sumprod = (sumprod_carrycarry << 65536) + ((sumprod_carrylow1 + sumprod_carrylow2) << 32768) + sumprod_low;

            always @(*) begin
                out = out1 + ((sumprod - out1 - out3) << 32768) + (out3 << 65536);
            end
        end else begin : gen_base_mult_65536
            base_multiplier #(65536) base_mult_inst (
                .x(x),
                .y(y),
                .out(out)
            );
        end
    endgenerate
endmodule

module karatsuba #(
    parameter num_single_lanes = 20,
    parameter n_bits = 97,
    parameter base_mult = 512
)(
    // input clk,
    input  [num_bits-1:0] x,
    input  [num_bits-1:0] y,
    output [2*num_bits:0] out
);
    function [31:0] log2;
        input [31:0] value;
        integer i;
        begin
            log2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                log2 = log2 + 1;
        end
    endfunction

    localparam num_bits = 1 << log2(n_bits);
    generate
        if (num_bits == 65536) begin
            sixty_five_five_three_six_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 32768) begin
            thirty_two_seven_six_eight_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 16384) begin
            sixteen_three_eight_four_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 8192) begin
            eight_one_two_two_bit_mult #(base_mult) dut (.x(x), .y(y), .out(out));
        end
        else if (num_bits == 4096) begin
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
            // assign out = 0;
        end
    endgenerate
    // initial begin
    //     $display("%d", n_bits);
    //     $display("%d", base_mult);
    // end
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
                // .clk(clk)
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