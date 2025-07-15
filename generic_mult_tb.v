// tb_top.v
`timescale 1ns / 1ps

module tb_top;

    parameter base_mult = 32;
    parameter interface_bits = 32;
    parameter bram_depth = 4;
    int size = 128;
    reg clk;
    wire [interface_bits-1:0] out;

    // Instantiate top
    generic_multiplier #(base_mult, interface_bits, bram_depth, 3) dut (
        .clk(clk),
        .size(size),
        .out(out)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        // Load memory into a1, a2, b1, b2 instances
        // Reference internal memory in the simulated BRAMs
        $readmemh("input_A.mem", dut.a1.mem);
        // $readmemh("input_B.mem", dut.a2.mem);
        $readmemh("input_A.mem", dut.b1.mem);
        // $readmemh("input_B.mem", dut.b2.mem);

        $dumpfile("sim.vcd");
        
        // $dumpvars(0, tb_top, dut.check.douta[0], dut.check.a_in[0], dut.check.a_in[1], dut.check.b_in[0], dut.check.b_in[1], dut.check.a_in[2], dut.check.a_in[3], dut.check.b_in[2], dut.check.b_in[3]);
        $dumpvars(0, tb_top, dut.douta, dut.a_in[0], dut.a_in[1], dut.b_in[0], dut.b_in[1], dut.a_in[2], dut.a_in[3], dut.b_in[2], dut.b_in[3]);
        
        // $dumpvars(0, dut);
        #400;
        $display("%h", dut.final_out);
        #300 $finish;
    end

endmodule
