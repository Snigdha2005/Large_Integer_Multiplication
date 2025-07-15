`timescale 1ns / 1ps

module tb_vectorised_schonhage;

    parameter num_bits = 32;
    parameter N = 12;
    parameter num_lanes = 5;
    parameter n = 8;

    reg  [num_bits-1:0] x [0:N-1];
    reg  [num_bits-1:0] y [0:N-1];
    wire [2*num_bits-1:0] out [0:N-1];
    reg clk = 0;
    int i;

    // Instantiate the DUT
    vectorised_schonhage #(
        .num_bits(num_bits),
        .N(N),
        .num_lanes(num_lanes),
        .n(n)
    ) dut (
        .clk(clk),
        .x(x),
        .y(y),
        .out(out)
    );

    always #5 clk = ~clk;

    initial begin
        // Initialize input arrays
        for (i = 0; i < N; i = i + 1) begin
            x[i] = 32'd1204 + i;   // e.g., 1204, 1205, 1206, ...
            y[i] = 32'd123 + i;    // e.g., 123, 124, 125, ...
        end

        #200; // Wait for combinational propagation

        // Display results
        $display("======================================");
        for (i = 0; i < N; i = i + 1) begin
            $display("x[%0d] = %0d, y[%0d] = %0d, out[%0d] = %0d", i, x[i], i, y[i], i, out[i]);
        end
        $display("======================================");

        #100
        $finish;
    end

    // initial begin
    //     $dumpfile("schonhage.vcd");
    //     $dumpvars(0, dut, dut.result[0]);
    // end
endmodule
