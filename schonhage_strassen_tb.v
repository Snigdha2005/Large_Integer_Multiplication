`timescale 1ns/1ps

module test_schonhage_strassen;

    parameter num_bits = 32;
    parameter n = 8;

    reg  [num_bits-1:0] x;
    reg  [num_bits-1:0] y;
    wire [31:0] result[0:n-1];
    wire [2*num_bits-1:0] out;

    // integer computed_result;
    // integer power_of_10;

    // Instantiate the DUT (Device Under Test)
    schonhage_strassen #(num_bits, n) uut (
        .x(x),
        .y(y),
        // .result1(result)
        .out(out)
    );

    initial begin
        // Test values
        x = 12042; // Decimal
        y = 1234;

        #100; // Wait for combinational logic to settle

        // $display("result digits");
        // for(int i = n-1; i >= 0; i = i - 1)begin
        //     $display("%d\t",result[i]);
        // end
        $display("%d", out);

        $finish;
    end
endmodule
