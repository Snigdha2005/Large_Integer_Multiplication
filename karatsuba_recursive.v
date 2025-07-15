// module karatsuba_recursive #(
//     parameter num_bits = 512,
//     parameter base_mult = 32
// )(
//     input  wire [num_bits-1:0] x,
//     input  wire [num_bits-1:0] y,
//     output wire [2*num_bits-1:0] out
// );

// generate
//     if (num_bits <= base_mult) begin : base_case
//         assign out = x * y;
//     end else begin : recurse
//         localparam fh = num_bits / 2;
//         localparam sh = num_bits - fh;

//         wire [fh-1:0] x0 = x[fh-1:0];
//         wire [sh-1:0] x1 = x[num_bits-1:fh];
//         wire [fh-1:0] y0 = y[fh-1:0];
//         wire [sh-1:0] y1 = y[num_bits-1:fh];

//         // Sign-extend or zero-extend smaller part before addition
//         wire [sh:0] x0_ext = {{(sh - fh + 1){1'b0}}, x0};
//         wire [sh:0] y0_ext = {{(sh - fh + 1){1'b0}}, y0};

//         wire [sh:0] sum_x = x1 + x0_ext;
//         wire [sh:0] sum_y = y1 + y0_ext;

//         wire [2*fh-1:0] out_p1;
//         wire [2*sh-1:0] out_p2;
//         wire [2*(sh+1)-1:0] out_p3;

//         karatsuba_recursive #(fh, base_mult) p1(.x(x0), .y(y0), .out(out_p1));
//         karatsuba_recursive #(sh, base_mult) p2(.x(x1), .y(y1), .out(out_p2));
//         karatsuba_recursive #(sh+1, base_mult) p3(.x(sum_x), .y(sum_y), .out(out_p3));

//         // Promote operands to same width before arithmetic
//         wire [2*(sh+1)-1:0] p2_ext = {{(2*(sh+1)-2*sh){1'b0}}, out_p2};
//         wire [2*(sh+1)-1:0] p1_ext = {{(2*(sh+1)-2*fh){1'b0}}, out_p1};

//         wire [2*(sh+1)-1:0] middle = out_p3 - p2_ext - p1_ext;

//         wire [2*num_bits-1:0] part1 = {{(2*num_bits - 2*sh){1'b0}}, out_p2} << (2*fh);
//         wire [2*num_bits-1:0] part2 = {{(2*num_bits - 2*(sh+1)){1'b0}}, middle} << fh;
//         wire [2*num_bits-1:0] part3 = {{(2*num_bits - 2*fh){1'b0}}, out_p1};

//         assign out = part1 + part2 + part3;
//     end
// endgenerate

// endmodule

// module karatsuba_recursive #(
//     parameter num_bits = 64,
//     parameter base_mult = 32
// )(
//     input clk,
//     input  wire [num_bits-1:0] x,
//     input  wire [num_bits-1:0] y,
//     output reg [2*num_bits-1:0] out
// );
//     wire [2*num_bits-1:0] outf;
// generate
//     if (num_bits <= base_mult) begin : base_case
//         assign outf = x * y;
//     end else begin : recurse
//         localparam fh = num_bits / 2;
//         localparam sh = num_bits - fh;

//         wire [fh-1:0] x0 = x[fh-1:0];
//         wire [sh-1:0] x1 = x[num_bits-1:fh];
//         wire [fh-1:0] y0 = y[fh-1:0];
//         wire [sh-1:0] y1 = y[num_bits-1:fh];

//         // Sign-extend or zero-extend smaller part before addition
//         wire [sh:0] x0_ext = {{(sh - fh + 1){1'b0}}, x0};
//         wire [sh:0] y0_ext = {{(sh - fh + 1){1'b0}}, y0};

//         wire [sh:0] sum_x = x1 + x0_ext;
//         wire [sh:0] sum_y = y1 + y0_ext;

//         wire [2*fh-1:0] out_p1;
//         wire [2*sh-1:0] out_p2;
//         wire [2*(sh+1)-1:0] out_p3;

//         karatsuba_recursive #(fh, base_mult) p1(.x(x0), .y(y0), .out(out_p1), .clk(clk));
//         karatsuba_recursive #(sh, base_mult) p2(.x(x1), .y(y1), .out(out_p2), .clk(clk));
//         karatsuba_recursive #(sh+1, base_mult) p3(.x(sum_x), .y(sum_y), .out(out_p3), .clk(clk));

//         // Promote operands to same width before arithmetic
//         wire [2*(sh+1)-1:0] p2_ext = {{(2*(sh+1)-2*sh){1'b0}}, out_p2};
//         wire [2*(sh+1)-1:0] p1_ext = {{(2*(sh+1)-2*fh){1'b0}}, out_p1};

//         wire [2*(sh+1)-1:0] middle = out_p3 - p2_ext - p1_ext;

//         wire [2*num_bits-1:0] part1 = {{(2*num_bits - 2*sh){1'b0}}, out_p2} << (2*fh);
//         wire [2*num_bits-1:0] part2 = {{(2*num_bits - 2*(sh+1)){1'b0}}, middle} << fh;
//         wire [2*num_bits-1:0] part3 = {{(2*num_bits - 2*fh){1'b0}}, out_p1};

//         assign outf = part1 + part2 + part3;
//     end
// endgenerate
//     always @(posedge clk) begin
//         out <= outf;
//     end
// endmodule


module karatsuba_recursive #(
    parameter num_bits = 64,
    parameter base_mult = 32
)(
    input start,
    input  wire [num_bits-1:0] x,
    input  wire [num_bits-1:0] y,
    output wire [2*num_bits-1:0] out
);

generate
    if (num_bits <= base_mult) begin : base_case
        assign out = (start == 1)? x * y: 0;
    end else begin : recurse
        localparam fh = num_bits / 2;
        localparam sh = num_bits - fh;

        wire [fh-1:0] x0 = x[fh-1:0];
        wire [sh-1:0] x1 = x[num_bits-1:fh];
        wire [fh-1:0] y0 = y[fh-1:0];
        wire [sh-1:0] y1 = y[num_bits-1:fh];

        // Sign-extend or zero-extend smaller part before addition
        wire [sh:0] x0_ext = {{(sh - fh + 1){1'b0}}, x0};
        wire [sh:0] y0_ext = {{(sh - fh + 1){1'b0}}, y0};

        wire [sh:0] sum_x = x1 + x0_ext;
        wire [sh:0] sum_y = y1 + y0_ext;

        wire [2*fh-1:0] out_p1;
        wire [2*sh-1:0] out_p2;
        wire [2*(sh+1)-1:0] out_p3;

        karatsuba_recursive #(fh, base_mult) p1(.x(x0), .y(y0), .out(out_p1), .start(start));
        karatsuba_recursive #(sh, base_mult) p2(.x(x1), .y(y1), .out(out_p2), .start(start));
        karatsuba_recursive #(sh+1, base_mult) p3(.x(sum_x), .y(sum_y), .out(out_p3), .start(start));

        // Promote operands to same width before arithmetic
        wire [2*(sh+1)-1:0] p2_ext = {{(2*(sh+1)-2*sh){1'b0}}, out_p2};
        wire [2*(sh+1)-1:0] p1_ext = {{(2*(sh+1)-2*fh){1'b0}}, out_p1};

        wire [2*(sh+1)-1:0] middle = out_p3 - p2_ext - p1_ext;

        wire [2*num_bits-1:0] part1 = {{(2*num_bits - 2*sh){1'b0}}, out_p2} << (2*fh);
        wire [2*num_bits-1:0] part2 = {{(2*num_bits - 2*(sh+1)){1'b0}}, middle} << fh;
        wire [2*num_bits-1:0] part3 = {{(2*num_bits - 2*fh){1'b0}}, out_p1};

        assign out = (start == 1) ? part1 + part2 + part3 : 0;
    end
endgenerate
endmodule

module top_kartasuba #(parameter num_bits = 64, parameter base_mult = 32)(
    input clk,
    input [base_mult-1:0] x,
    input [base_mult-1:0] y,
    output reg [base_mult-1:0] out
);
    localparam num_blocks = num_bits / base_mult;
    reg [num_bits-1:0] a;
    reg [num_bits-1:0] b;
    reg [2*num_bits:0] outf;
    reg start;
    int count = 0;

    always @(posedge clk)begin
        if(count < num_blocks)begin
            a <= {a, x};
            b <= {b, y};
            start <= 0;
        end
        if(count == num_blocks) begin
            start <= 1;
        end
        count <= count + 1;
    end

    karatsuba_recursive #(num_bits, base_mult) dut(start, a, b, outf);

    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if (count >= 5 && out_idx < 2*num_bits) begin
            out <= outf[out_idx +: 32];
            out_idx <= out_idx + 32;
        end
    end
endmodule