`timescale 1ns / 1ps

module tb_generic_multiplier;

    parameter base_mult = 32;
    parameter bram_depth = 4;
    
    reg clk;
    reg [31:0] size;
    wire [base_mult-1:0] out;

    // Instantiate the DUT
    generic_multiplier #(
        .base_mult(base_mult),
        .bram_depth(bram_depth)
    ) dut (
        .clk(clk),
        .size(size),
        .out(out)
    );

    // Clock generation: 100MHz
    always #20 clk = ~clk;

    // Initial stimulus
    initial begin
        clk = 0;
        size = 128;  // 128-bit inputs = 4 chunks

        // Load BRAMs with values (manually or using $readmemh)
        // For example, input_A1.mem should contain 4 hex lines, one for each 32-bit word
        $readmemh("input_A1.mem", dut.a1.mem);  // A
        $readmemh("input_B1.mem", dut.a2.mem);  // A duplicate
        $readmemh("input_A1.mem", dut.b1.mem);  // B
        $readmemh("input_B1.mem", dut.b2.mem);  // B duplicate

        // Dump all relevant internal signals to the VCD
        
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_generic_multiplier);
        $dumpvars(0, dut.clk);
        $dumpvars(0, dut.count);
        // $dumpvars(0, dut.j);
        // $dumpvars(0, dut.i);
        // $dumpvars(0, dut.final_out);
        // $dumpvars(0, dut.a[0], dut.a[1], dut.a[2], dut.a[3]);
        // $dumpvars(0, dut.b[0], dut.b[1], dut.b[2], dut.b[3]);
        $dumpvars(0, dut.x[0], dut.x[1], dut.x[2], dut.x[3]);
        $dumpvars(0, dut.y[0], dut.y[1], dut.y[2], dut.y[3]);
        // $dumpvars(0, dut.a_queue[0], dut.a_queue[1], dut.a_queue[2], dut.a_queue[3]);
        // $dumpvars(0, dut.b_queue[0], dut.b_queue[1], dut.b_queue[2], dut.b_queue[3]);
        $dumpvars(0, dut.partial_out[0], dut.partial_out[1], dut.partial_out[2], dut.partial_out[3]);
        // $dumpvars(0, dut.shift[0], dut.shift[1], dut.shift[2], dut.shift[3]);

        // Wait long enough for computation to complete
        #4000;

        $display("Final Output: %h", dut.final_out);
        $finish;
    end

endmodule
