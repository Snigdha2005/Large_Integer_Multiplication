`timescale 1ns/1ps

module tb_vectorised_karatsuba;

    // Parameters
    parameter num_single_lanes = 14348907;
    parameter num_bits = 16;
    parameter N = 21;
    parameter num_lanes = 7;
    parameter base_mult = 2;

    // DUT Signals
    logic [num_bits-1:0] x [0:N-1];
    logic [num_bits-1:0] y [0:N-1];
    wire  [2*num_bits:0] out [0:N-1];
    reg clk1 = 0;
    // reg clk2 = 0;
    // Instantiate the DUT
    vectorised_karatsuba #(
        .num_single_lanes(num_single_lanes),
        .num_bits(num_bits),
        .N(N),
        .num_lanes(num_lanes),
        .base_mult(base_mult)
    ) dut (
        .x(x),
        .y(y),
        .out(out),
        .clk1(clk1)
        // .clk2(clk2)
    );
    always #5 clk1 = ~clk1;
    // always #30 clk2 = ~clk2;
    // Test values and simulation
    initial begin
        // Random input initialization
        int i;
        for (i = 0; i < N; i++) begin
            x[i] = $urandom_range(0, (1 << num_bits) - 1);
            y[i] = $urandom_range(0, (1 << num_bits) - 1);
        end

        // Wait for combinational logic to settle
        #300;

        // Print results
        $display("\n%-5s %-5s | %-9s %-15s", "X", "Y", "OUT", "Expected");
        $display("---------------------------------------------------");
        for (i = 0; i < N; i++) begin
            int expected;
            expected = x[i] * y[i];
            $display("%-5d %-5d | %-9d %-15d", x[i], y[i], out[i], expected);
        end

        #100;
        $finish;
    end
    initial begin
        $dumpfile("karatsuba.vcd");
        $dumpvars(0, dut);
    end

endmodule
