`define POW3(n) ( \
    (n == 0) ? 1 : \
    (n == 1) ? 3 : \
    (n == 2) ? 9 : \
    (n == 3) ? 27 : \
    (n == 4) ? 81 : \
    (n == 5) ? 243 : \
    (n == 6) ? 729 : \
    (n == 7) ? 2187 : \
    (n == 8) ? 6561 : \
    (n == 9) ? 19683 : \
    (n == 10) ? 59049 : \
    -1)  // fallback

function automatic int log2;
    input int value;
    int i;
    begin
        log2 = 0;
        for (i = value - 1; i > 0; i = i >> 1)
            log2 = log2 + 1;
    end
endfunction

module two_bit_mult(input [1:0] a, input [1:0] b, output [5:0] out);
    assign out = a * b;
endmodule

module karatsuba_multiplication #(parameter N = 4, parameter M = 4)(input [N-1:0] x, input [M-1:0] y, output [K-1:0] out);
    parameter max_len = (N > M)? N: M;
    parameter MAX_BIT_LENGTH = 4096;
    parameter num_lanes = POW3(log2(max_len) - 1);
    genvar i;
    reg [max_len-1:0] x1;
    reg [max_len-1:0] y1;
    reg [K-1:0] out1;
    reg 
    wire null_inp;
    
    assign null_inp = (N == 0 || M == 0)? 1:0;

    initial begin
        x1 = 0;
        y1 = 0;
        out1 = 0;
    end

    always @(posedge clk) begin
        x1 <= {0, x1};
        y1 <= {0, y1};
        out <= (null_inp == 1)? 0: out1;
    end

    generate
        for(i = 0; i < num_lanes; i = i + 1) begin
            two_bit_mult uut1();
        end
    endgenerate

endmodule

// module karatsuba_recursive #(
//     parameter num_bits = 64,
//     parameter base_mult = 32
// )(
//     input clk,
//     input  wire [num_bits-1:0] x,
//     input  wire [num_bits-1:0] y,
//     output reg [2*num_bits-1:0] out
// );

// generate
//     if (num_bits <= base_mult) begin : base_case
//         always @(posedge clk) begin
//             out <= x * y;
//         end
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
//         reg [2*fh-1:0] out_p1_reg;
//         wire [2*sh-1:0] out_p2;
//         reg [2*sh-1:0] out_p2_reg;
//         wire [2*(sh+1)-1:0] out_p3;
//         reg [2*(sh+1)-1:0] out_p3_reg;

//         karatsuba_recursive #(fh, base_mult) p1(.x(x0), .y(y0), .out(out_p1));
//         karatsuba_recursive #(sh, base_mult) p2(.x(x1), .y(y1), .out(out_p2));
//         (* dont_touch = "yes" *) karatsuba_recursive #(sh+1, base_mult) p3(.x(sum_x), .y(sum_y), .out(out_p3));

//         always @(posedge clk)begin
//             out_p1_reg <= out_p1;
//             out_p2_reg <= out_p2;
//             out_p3_reg <= out_p3;
//         end
        
//         // Promote operands to same width before arithmetic
//         reg [2*(sh+1)-1:0] p2_ext;
//         reg [2*(sh+1)-1:0] p1_ext;

//         reg [2*(sh+1)-1:0] middle;

//         reg [2*num_bits-1:0] part1;
//         reg [2*num_bits-1:0] part2;
//         reg [2*num_bits-1:0] part3;
        
//         always @(posedge clk) begin
//             p2_ext <= {{(2*(sh+1)-2*sh){1'b0}}, out_p2_reg};
//             p1_ext <= {{(2*(sh+1)-2*fh){1'b0}}, out_p1_reg};
//             middle <= out_p3_reg - p2_ext - p1_ext;
//             part1 <= {{(2*num_bits - 2*sh){1'b0}}, out_p2_reg} << (2*fh);
//             part2 <= {{(2*num_bits - 2*(sh+1)){1'b0}}, middle} << fh;
//             part3 <= {{(2*num_bits - 2*fh){1'b0}}, out_p1_reg};
//         end
// //        assign out = part1 + part2 + part3;
//         always @(posedge clk) begin
//             out <= part1 + part2 + part3;
//         end
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

// generate
//     if (num_bits <= base_mult + 1) begin : base_case
//         always @(posedge clk) begin
//             out <= x * y;
//         end
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
//         reg [2*fh-1:0] out_p1_reg;
//         wire [2*sh-1:0] out_p2;
//         reg [2*sh-1:0] out_p2_reg;
//         wire [2*(sh+1)-1:0] out_p3;
//         reg [2*(sh+1)-1:0] out_p3_reg;

//         karatsuba_recursive #(fh, base_mult) p1(.x(x0), .y(y0), .out(out_p1));
//         karatsuba_recursive #(sh, base_mult) p2(.x(x1), .y(y1), .out(out_p2));
//         (* dont_touch = "yes" *) karatsuba_recursive #(sh+1, base_mult) p3(.x(sum_x), .y(sum_y), .out(out_p3));

//         always @(posedge clk)begin
//             out_p1_reg <= out_p1;
//             out_p2_reg <= out_p2;
//             out_p3_reg <= out_p3;
//         end
        
//         // Promote operands to same width before arithmetic
//         reg [2*(sh+1)-1:0] p2_ext;
//         reg [2*(sh+1)-1:0] p1_ext;

//         reg [2*(sh+1)-1:0] middle;

// //        reg [2*num_bits-1:0] part1;
// //        reg [2*num_bits-1:0] part2;
// //        reg [2*num_bits-1:0] part3;
        
//         always @(posedge clk) begin
//             p2_ext <= {{(2*(sh+1)-2*sh){1'b0}}, out_p2_reg};
//             p1_ext <= {{(2*(sh+1)-2*fh){1'b0}}, out_p1_reg};
//             middle <= out_p3_reg - p2_ext - p1_ext;
//             out <= ({{(2*num_bits - 2*sh){1'b0}}, out_p2_reg} << (2*fh)) + ({{(2*num_bits - 2*(sh+1)){1'b0}}, middle} << fh) + ({{(2*num_bits - 2*fh){1'b0}}, out_p1_reg});
//         end
// //        assign out = part1 + part2 + part3;
// //        always @(posedge clk) begin
// //            out <= part1 + part2 + part3;
// //        end
//     end
// endgenerate

// endmodule

// module karatsuba_recursive #(
//     parameter num_bits = 64,
//     parameter base_mult = 32,
//     parameter NUM_LATENCY = 8
// )(
//     input clk,
//     input  wire [base_mult-1:0] x,
//     input  wire [base_mult-1:0] y,
//     output reg [base_mult-1:0] out
// );

//     localparam num_blocks = num_bits / (base_mult);
//     integer count = 0;
//     reg [num_bits-1:0] a;
//     reg [num_bits-1:0] b;
//     reg [2*num_bits:0] outf;
//     reg accumulation_done;
//     always @(posedge clk) begin
//         if (count < num_blocks) begin
//             a <= {a, x};
//             b <= {b, y};
//         end
//         count <= count + 1;
//     end
// generate
//     if (num_bits <= base_mult + 1) begin : base_case
//         always @(posedge clk) begin
//             outf <= x * y;
//             accumulation_done <= 1;
//         end
//     end else begin : recurse
//         localparam fh = num_bits / 2;
//         localparam sh = num_bits - fh;

//         wire [fh-1:0] x0 = a[fh-1:0];
//         wire [sh-1:0] x1 = a[num_bits-1:fh];
//         wire [fh-1:0] y0 = b[fh-1:0];
//         wire [sh-1:0] y1 = b[num_bits-1:fh];

//         // Sign-extend or zero-extend smaller part before addition
//         wire [sh:0] x0_ext = {{(sh - fh + 1){1'b0}}, x0};
//         wire [sh:0] y0_ext = {{(sh - fh + 1){1'b0}}, y0};

//         wire [sh:0] sum_x = x1 + x0_ext;
//         wire [sh:0] sum_y = y1 + y0_ext;

//         wire [2*fh-1:0] out_p1;
//         reg [2*fh-1:0] out_p1_reg;
//         wire [2*sh-1:0] out_p2;
//         reg [2*sh-1:0] out_p2_reg;
//         wire [2*(sh+1)-1:0] out_p3;
//         reg [2*(sh+1)-1:0] out_p3_reg;

//         karatsuba_recursive #(fh, base_mult, 8) p1(.x(x0), .y(y0), .out(out_p1), .clk(clk));
//         karatsuba_recursive #(sh, base_mult, 8) p2(.x(x1), .y(y1), .out(out_p2), .clk(clk));
//         karatsuba_recursive #(sh+1, base_mult, 8) p3(.x(sum_x), .y(sum_y), .out(out_p3), .clk(clk));

//         always @(posedge clk)begin
//             out_p1_reg <= out_p1;
//             out_p2_reg <= out_p2;
//             out_p3_reg <= out_p3;
//         end
        
//         // Promote operands to same width before arithmetic
//         reg [2*(sh+1)-1:0] p2_ext;
//         reg [2*(sh+1)-1:0] p1_ext;

//         reg [2*(sh+1)-1:0] middle;

//         always @(posedge clk) begin
//             p2_ext <= {{(2*(sh+1)-2*sh){1'b0}}, out_p2_reg};
//             p1_ext <= {{(2*(sh+1)-2*fh){1'b0}}, out_p1_reg};
//             middle <= out_p3_reg - p2_ext - p1_ext;
//             outf <= ({{(2*num_bits - 2*sh){1'b0}}, out_p2_reg} << (2*fh)) + ({{(2*num_bits - 2*(sh+1)){1'b0}}, middle} << fh) + ({{(2*num_bits - 2*fh){1'b0}}, out_p1_reg});
//             if(count == NUM_LATENCY) accumulation_done <= 1;
//         end
//     end
// endgenerate
    
//     reg [31:0] out_idx = 0;
//     always @(posedge clk)begin
//         if (accumulation_done && out_idx < 2*num_bits) begin
//             out <= outf[out_idx +: 32];
//             out_idx <= out_idx + 32;
//         end
//     end
// endmodule
