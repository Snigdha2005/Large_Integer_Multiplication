module point_wise_mult #(parameter n = 256, parameter MOD = 734003)(
    input [31:0] a [0:n-1],
    input [31:0] b [0:n-1],
    output reg [31:0] out [0:n-1],
    input clk
);
    wire [63:0] out1 [0:n-1];
    genvar i;
    int j;
    generate
        for (i = 0; i < n; i = i + 1) begin : gen_lanes
            assign out1[i] = (a[i] * b[i]) % MOD;
        end
        always @(posedge clk)begin
            for(j = 0; j < n; j = j + 1) begin
                out[j] = out1[j];
            end
        end
    endgenerate
endmodule

module extract_digits #(parameter n = 71, parameter num_bits = 256)(
    input clk,
    input [num_bits-1:0] x,
    output reg [31:0] digits[0:n-1]
);
    reg [num_bits-1:0] temp;
    integer index;

    always @(posedge clk) begin
        temp = x;
        index = 0;

        for(index = 0; index < n; index =  index + 1) begin
            if (temp > 0) begin
                digits[index] = temp % 10;
                temp = temp / 10;
            end
            else begin
                digits[index] = 0;
            end
        end
        // while (temp > 0 && index < n) begin
        //     digits[index] = temp % 10;
        //     temp = temp / 10;
        //     index = index + 1;
        // end
        // // Zero padding for remaining digits
        // while (index < n) begin
        //     digits[index] = 0;
        //     index = index + 1;
        // end
        // $display("extracted digits");
        // for(int i = 0; i < n; i = i + 1)begin
        //     $display("digit = %d, i = %d", digits[i], i);
        // end
    end
endmodule

module ntt #(
    parameter MOD = 7340033,
    parameter ROOT = 5,
    parameter ROOT_1 = 4404020,
    parameter ROOT_PW = 1 << 20,
    parameter N = 8
)(
    input clk,
    input inverse,
    input [31:0] a_in [0:N-1],
    output reg [31:0] a_out [0:N-1]
);

    reg [31:0] a [0:N-1];
    int temp;
    reg [63:0] wlen;
    reg [63:0] w;
    int u, v;
    int i;
    int j;
    int b;
    int len;
    int n_1;
    integer idx;
    reg [63:0] ll = 63'b111111;

    function [31:0] modinv;
        input [31:0] x;
        input [31:0] m;
        int m0;
        int t;
        int q;
        int x0;
        int  x1;
        begin
            x0 = 0; x1 = 1; m0 = m;
            if(m == 1) modinv = 0;
            for (i = 0; i < 32 && x > 1; i = i + 1) begin
                q = x / m;
                t = m;

                m = x % m;
                x = t;
                t = x0;

                x0 = x1 - q * x0;
                x1 = t;
            end
            if (x1 < 0) begin
                x1 = x1 + m0;
            end
            modinv = x1;
        end
    endfunction

    always @(posedge clk) begin
        for (idx = 0; idx < N; idx = idx + 1) begin
            a[idx] = a_in[idx];
            // $display("a = %d ain = %d, idx = %d", a[idx], a_in[idx], idx);
        end
        j = 0;
        for (i = 1; i < N; i = i + 1) begin
            b = N >> 1;
            // $display("%d", b);
            for(j = j; j & b; b = b >> 1) begin
                j = j ^ b;
            end
            j = j ^ b;

            if (i < j) begin
                temp = a[i];
                a[i] = a[j];
                a[j] = temp;
            end
        end
        // for (idx = 0; idx < N; idx = idx + 1) begin
        //     $display("a = %d\t", a[idx]);
        // end
        for (len = 2; len <= N; len = len << 1) begin
            wlen = inverse ? ROOT_1 : ROOT;
            // $display("wlen = %d ", wlen);
            for (i = len; i < ROOT_PW; i = i << 1)begin
                wlen = (wlen * wlen % MOD);
                // $display("wlen = %d, len = %d, i = %d", wlen, len, i);
            end
            for (i = 0; i < N; i = i + len) begin
                w = 1;
                for (j = 0; j < len / 2; j = j + 1) begin
                    u = a[i + j];
                    v = a[i + j + (len/2)] * w % MOD;

                    a[i + j] = (u + v < MOD) ? (u + v) : (u + v - MOD);
                    a[i + j + (len / 2 )] = ((u - v) >= 0) ? (u - v) : (u - v + MOD);

                    w = (w * wlen % MOD);
                end
            end
        end

        if (inverse) begin
            n_1 = modinv(N, MOD);
            for (i = 0; i < N; i = i + 1)
                a[i] = (a[i] * n_1 % MOD);
        end

        for (idx = 0; idx < N; idx = idx + 1)begin
            a_out[idx] = a[idx];
            // $display("aout = %d a = %d, idx = %d", a_out[idx], a[idx], idx);
        end
    end
endmodule

module carry_prop #(parameter n = 8)(
    input clk,
    input [31:0] result[0:n-1],
    output reg [31:0] final_result[0:n-1]
);
    int carry;
    int i;
    reg [63:0] val;
    always @(posedge clk) begin
        carry  = 0;
        // $display("%d", result[0]);
        for(i = 0; i < n; i = i + 1) begin
            final_result[i] = result[i];
            // $display("%d", final_result[i]);
        end
        for(i = 0; i < n; i = i + 1)begin
            val = final_result[i] + carry;
            final_result[i] = val % 10;
            // $display("%d", final_result[i]);
            carry = val / 10;
        end
        // for(i = 0; i < n; i = i + 1) begin
        //     // final_result[i] = result[i];
        //     $display("%d %d", final_result[i], i);
        // end
    end
endmodule

module reconstruction_result #(parameter n = 8, parameter num_bits = 32)(
    input clk,
    input [31:0] result[0:n-1],
    output reg [2*num_bits-1:0] out
);
    int base;
    always @(posedge clk) begin
        base = 1;
        out = 0;
        for(int i = 0; i < n; i = i + 1)begin
            out = result[i] * base + out;
            base = base * 10;
        end
    end
endmodule

module schonhage_strassen #(parameter num_bits = 32, parameter n = 8)(
    input clk,
    input [num_bits-1:0] x,
    input [num_bits-1:0] y,
    output [2*num_bits-1:0] out
    // output [31:0] result1[0:n-1]
);
    wire [31:0] a_digits [0:n-1];
    wire [31:0] b_digits [0:n-1];
    wire [31:0] a_ntt [0:n-1];
    wire [31:0] b_ntt [0:n-1];
    wire [31:0] c_ntt [0:n-1];
    wire [31:0] result [0:n-1];
    wire [31:0] result1 [0:n-1];
    
    extract_digits #(n, num_bits) ext1(clk, x, a_digits);
    extract_digits #(n, num_bits) ext2(clk, y, b_digits);

    ntt #(7340033, 5, 4404020, 1<<20, n) fwd1(clk, 1'b0, a_digits, a_ntt);
    ntt #(7340033, 5, 4404020, 1<<20, n) fwd2(clk, 1'b0, b_digits, b_ntt);

    point_wise_mult #(n, 7340033) pwm(a_ntt, b_ntt, c_ntt, clk);

    ntt #(7340033, 5, 4404020, 1<<20, n) inv(clk, 1'b1, c_ntt, result);

    carry_prop #(n) carry_p(clk, result, result1);

    reconstruction_result #(n, num_bits) reconst(clk, result1, out);
    
endmodule

module vectorised_schonhage #(parameter num_bits = 32, parameter N = 10, parameter num_lanes = 5, parameter n = 8)(
    input clk,
    input [num_bits-1:0] x [0:N-1],
    input [num_bits-1:0] y [0:N-1],
    output [2*num_bits-1:0] out [0:N-1]
);

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_lanes
            schonhage_strassen #(num_bits, n) u_base (
                .clk(clk),
                .x(x[i]),
                .y(y[i]),
                .out(out[i])
            );
        end
    endgenerate
endmodule