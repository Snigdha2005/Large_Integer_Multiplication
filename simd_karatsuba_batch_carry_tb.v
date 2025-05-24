`timescale 1ns / 1ps

module tb_vectorised_karatsuba;

    parameter num_single_lanes = 14348907;
    parameter num_bits = 8;
    parameter N = 10;
    parameter num_lanes = 4;
    parameter base_mult = 2;

    reg clk;
    reg reset;
    reg start;
    reg [num_bits-1:0] x [0:N-1];
    reg [num_bits-1:0] y [0:N-1];
    wire [2*num_bits:0] out [0:N-1];
    wire done;

    // Instantiate the DUT
    vectorised_karatsuba #(
        .num_single_lanes(num_single_lanes),
        .num_bits(num_bits),
        .N(N),
        .num_lanes(num_lanes),
        .base_mult(base_mult)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .x(x),
        .y(y),
        .out(out),
        .done(done)
    );

    // Clock generation
    always #10 clk = ~clk;

    // Stimulus
    integer i;

    initial begin
        clk = 0;
        reset = 1;
        start = 0;

        // Reset
        #20;
        reset = 0;

        // Assign input values
        for (i = 0; i < N; i = i + 1) begin
            x[i] = i + 1;         // x = 1, 2, 3, ...
            y[i] = i + 10;        // y = 10, 11, 12, ...
        end

        // Start processing
        #10;
        start = 1;
        #10;
        start = 0;

        // Wait for done
        wait(done);

        // Display results
        #10;
        $display("X     Y     | OUT");
        $display("-----------------------------");
        for (i = 0; i < N; i = i + 1) begin
            $display("%d * %d = %d", x[i], y[i], out[i]);
        end

        $finish;
    end
endmodule
