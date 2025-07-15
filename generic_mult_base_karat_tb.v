`timescale 1ns / 1ps

module tb_top;

    // Parameters
    parameter base_mult = 32;
    parameter interface_bits = 32;
    parameter bram_depth = 4;  // Smaller BRAM for quick simulation
    int size = 128;            // Operands are 128 bits (4 x 32-bit chunks)

    reg clk;
    wire [interface_bits-1:0] out;

    // DUT instantiation
    generic_multiplier #(base_mult, interface_bits, bram_depth, 3) dut (
        .clk(clk),
        .size(size),
        .out(out)
    );

    // Clock generation (100 MHz)
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        clk = 0;

        // Initialize memory (you can edit input_A.mem with hex values)
        $readmemh("input_A1.mem", dut.a1.mem); // Load A
        $readmemh("input_B1.mem", dut.a2.mem); // Duplicate to simulate interleaved access
        $readmemh("input_A1.mem", dut.b1.mem); // Load B (same as A for squaring)
        $readmemh("input_B1.mem", dut.b2.mem); // Duplicate

        // Waveform output
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_top);
        $dumpvars(0, dut.a_in[0], dut.a_in[1], dut.b_in[0], dut.b_in[1]);
        $dumpvars(0, dut.final_out, dut.mult_pipe, dut.shift_pipe3);

        // Wait for accumulation to finish
        #400;

        // Display final product
        $display("Final product: %h", dut.final_out);

        #200 $finish;
    end

endmodule
