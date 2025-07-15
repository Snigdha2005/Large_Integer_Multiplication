`timescale 1ns / 1ps

module tb_traditional;

    parameter interface_bits = 32;
    parameter bram_depth = 4;
    reg clk;
    int size = 128;  // Using 7 bits for 0–128 range
    wire [interface_bits-1:0] out;

    // Instantiate DUT
    traditional_multiplier #(interface_bits, bram_depth) dut (
        .clk(clk),
        .size(size),
        .out(out)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    initial begin
        clk = 0;

        // Load inputs into BRAMs
        $readmemh("input_A1.mem", dut.a1.mem);
        $readmemh("input_B1.mem", dut.a2.mem);
        $readmemh("input_A1.mem", dut.b1.mem);
        $readmemh("input_B1.mem", dut.b2.mem);

        // VCD output for waveform dump
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_traditional, dut);

        #500;

        $display("Final Output = %h", out);
        $finish;
    end

endmodule
