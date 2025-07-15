`timescale 1ns / 1ps

module tb_generic_multiplier;

    // Parameters
    parameter base_mult = 32;
    parameter interface_bits = 32;
    parameter bram_depth = 4;

    reg clk;
    wire [interface_bits-1:0] out;

    // Operand bit width
    int size = 128;

    // DUT instance
    generic_multiplier #(base_mult, interface_bits, bram_depth) dut (
        .clk(clk),
        .size(size),
        .out(out)
    );

    // Clock generation: 100 MHz -> 10ns period
    always #5 clk = ~clk;

    initial begin
        clk = 0;

        // Load data into simulated BRAMs
        $readmemh("input_A1.mem", dut.a1.mem); // Load A into a1
        $readmemh("input_B1.mem", dut.a2.mem); // Same A into a2
        $readmemh("input_A1.mem", dut.b1.mem); // Same A into b1
        $readmemh("input_B1.mem", dut.b2.mem); // Same A into b2 (squaring)

        // Dump waveform
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_generic_multiplier);
        $dumpvars(1, dut);
        $display("Starting simulation...");

        // Simulate enough time for full operation
        #400;
        $display("Final output = %h", dut.final_out);
        $finish;
    end

endmodule
