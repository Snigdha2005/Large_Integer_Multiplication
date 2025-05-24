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