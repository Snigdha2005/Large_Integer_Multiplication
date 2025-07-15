`timescale 1ns / 1ps

module tb_schoolbook;

    // Parameters
    parameter num_bits = 1024;  // Smaller for simulation feasibility
    parameter N = 10;
    parameter num_lanes = 5;

    // Inputs and Outputs
    reg [num_bits-1:0] x [0:N-1];
    reg [num_bits-1:0] y [0:N-1];
    wire [2*num_bits:0] out [0:N-1];

    // Instantiate the DUT
    schoolbook #(num_bits, N, num_lanes) dut (
        .x(x),
        .y(y),
        .out(out)
    );

    integer i;

    initial begin
        // Initialize inputs
        for (i = 0; i < N; i = i + 1) begin
            x[i] = i + 1;
            y[i] = (i + 1) * 2;
        end

        // Wait for logic to settle (in combinational design)
        #10;

        // Display results
        $display("=== Schoolbook Multiplication Results ===");
        for (i = 0; i < N; i = i + 1) begin
            $display("x[%0d] = %0d, y[%0d] = %0d --> out[%0d] = %0d", 
                i, x[i], i, y[i], i, out[i]);
        end

        $finish;
    end

endmodule
