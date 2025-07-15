`timescale 1ns / 1ps

module karatsuba_tb;
    reg  [7:0] a, b;
    wire [16:0] out_custom;
    reg  [16:0] out_reference;

    // Instantiate the largest multiplier module
    eight_bit_mult dut (
        .x(a),
        .y(b),
        .out(out_custom)
    );

    initial begin
        // Random test
        a = 8'h0F;
        b = 8'h11;

        #10;
        out_reference = a * b;

        $display("A           = %b", a);
        $display("B           = %b", b);
        $display("Custom OUT  = %b", out_custom);
        $display("Golden OUT  = %b", out_reference);

        if (out_custom === out_reference)
            $display("Test Passed");
        else
            $display("Test Failed");

        a = 8'h22;
        b = 8'hFF;

        #10;
        out_reference = a * b;

        $display("A           = %b", a);
        $display("B           = %b", b);
        $display("Custom OUT  = %b", out_custom);
        $display("Golden OUT  = %b", out_reference);

        if (out_custom === out_reference)
            $display("Test Passed");
        else
            $display("Test Failed");

        a = 8'h15;
        b = 8'h13;

        #10;
        out_reference = a * b;

        $display("A           = %b", a);
        $display("B           = %b", b);
        $display("Custom OUT  = %b", out_custom);
        $display("Golden OUT  = %b", out_reference);

        if (out_custom === out_reference)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;
    end
endmodule
