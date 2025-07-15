`timescale 1ns / 1ps

module tb_generic_multiplier;

    parameter base_mult = 128;
    parameter interface_bits = 128;
    parameter bram_depth = 2048;

    reg clk;
    reg [19:0] size;
    wire [interface_bits-1:0] out;

    // Instantiate the DUT
    generic_multiplier #(
        .base_mult(base_mult),
        .interface_bits(interface_bits),
        .bram_depth(bram_depth)
    ) dut (
        .clk(clk),
        .size(size),
        .out(out)
    );

    // Clock generation: 100 MHz
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        clk = 0;
        size = 128; // 64-bit input → 2 blocks

        // Preload input BRAMs
        $readmemh("A1.mem", dut.a1.mem);
        $readmemh("B1.mem", dut.a2.mem);
        $readmemh("A1.mem", dut.b1.mem);
        $readmemh("B1.mem", dut.b2.mem);

        // Final output memory will accumulate the shifted partials
        $readmemh("zero.mem", dut.final_out.mem);

        // Dump VCD
        $dumpfile("generic_multiplier.vcd");
        $dumpvars(0, tb_generic_multiplier);
        $dumpvars(0, dut);
        $dumpvars(0, dut.final_out.mem[0], dut.final_out.mem[1], dut.final_out.mem[2], dut.final_out.mem[3], dut.final_out.mem[4], dut.final_out.mem[5], dut.final_out.mem[6]);
        // Wait enough time for all accumulation
        #9000;
        $finish;
    end
    always @(dut.carry) begin
        $display("%d", dut.count);
    end
endmodule
