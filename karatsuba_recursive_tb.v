// `timescale 1ns / 1ps

// module karatsuba_recursive_tb;

//     // Parameters
//     parameter NUM_BITS = 128;
//     parameter BASE_MULT = 32;
//     localparam OUT_BITS = 2 * NUM_BITS;

//     // Inputs
//     reg [NUM_BITS-1:0] x, y;
//     reg clk = 0;;
//     // Output
//     reg start = 1;
//     wire [OUT_BITS-1:0] out;

//     // Instantiate the Karatsuba module
//     karatsuba_recursive #(NUM_BITS, BASE_MULT) dut (
//         .clk(clk),
//         .start(start),
//         .x(x),
//         .y(y),
//         .out(out)
//     );

//     // Reference output
//     reg [OUT_BITS-1:0] expected;

//     always #5 clk = ~clk;
//     // Task to apply stimulus and check result
//     task run_test(input [NUM_BITS-1:0] in1, input [NUM_BITS-1:0] in2);
//     begin
//         x = in1;
//         y = in2;
//         expected = in1 * in2;

//         #1000;  // Wait for combinational logic to settle

//         if (out !== expected) begin
//             $display("Mismatch: x=%0d, y=%0d", in1, in2);
//             $display("   Expected: %0d", expected);
//             $display("   Got     : %0d", out);
//         end else begin
//             $display("Pass: x=%0d, y=%0d -> %0d", in1, in2, out);
//         end
//     end
//     endtask

//     // Main stimulus
//     initial begin
//         $display("Starting Karatsuba recursive testbench...");
        
//         // Test edge cases
//         run_test(0, 0);
//         run_test(0, 1);
//         run_test(1, 0);
//         run_test(1, 1);
//         run_test(112098, 123456789);
//         run_test({NUM_BITS{1'b1}}, {NUM_BITS{1'b1}}); // Max values

//         // Random tests
//         repeat (30) begin
//             run_test({$random} % 640000, {$random} % 640000);
//         end

//         $display("Testbench completed.");
//         $finish;
//     end

//     initial begin
//         $dumpfile("karatsuba_r.vcd");
//         $dumpvars(0, dut);
//     end
// endmodule
`timescale 1ns / 1ps

module tb_top_karatsuba;

    parameter num_bits = 1024;
    parameter base_mult = 32;

    reg clk;
    reg [base_mult-1:0] x, y;
    wire [base_mult-1:0] out;

    // Instantiate DUT
    top_kartasuba #(num_bits, base_mult) dut (
        .clk(clk),
        .x(x),
        .y(y),
        .out(out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Test logic
    initial begin
        // Inputs
        reg [num_bits-1:0] x_full = 1024'h1233784633475734564483265786837978_9ABCDEF0;
        reg [num_bits-1:0] y_full = 1024'h084273743883834798684839FEDC844BA9_87654321;
        reg [2*num_bits-1:0] expected_result;
        
        x = x_full[1021:992];
        y = y_full[1021:992];
        #10;

        x = x_full[991:960];
        y = y_full[991:960];
        #10;
        x = x_full[959:928];
        y = y_full[959:928];
        #10;
        x = x_full[927:896];
        y = y_full[927:896];
        #10;
        x = x_full[895:864];
        y = y_full[895:864];
        #10;

        x = x_full[863:832];
        y = y_full[863:832];
        #10;

        // Feed MSB part first
        x = x_full[831:800];
        y = y_full[831:800];
        #10;

        // Then LSB part
        x = x_full[799:768];
        y = y_full[799:768];
        #10;




        x = x_full[767:736];
        y = y_full[767:736];
        #10;
        x = x_full[735:704];
        y = y_full[735:704];
        #10;
        x = x_full[703:672];
        y = y_full[703:672];
        #10;
        x = x_full[671:640];
        y = y_full[671:640];
        #10;
        x = x_full[639:608];
        y = y_full[639:608];
        #10;

        x = x_full[607:576];
        y = y_full[607:576];
        #10;

        // Feed MSB part first
        x = x_full[575:544];
        y = y_full[575:544];
        #10;

        // Then LSB part
        x = x_full[543:512];
        y = y_full[543:512];
        #10;
        x = x_full[511:480];
        y = y_full[511:480];
        #10;

        x = x_full[479:448];
        y = y_full[479:448];
        #10;
        x = x_full[447:416];
        y = y_full[447:416];
        #10;
        x = x_full[415:384];
        y = y_full[415:384];
        #10;
        x = x_full[383:352];
        y = y_full[383:352];
        #10;

        x = x_full[351:320];
        y = y_full[351:320];
        #10;

        // Feed MSB part first
        x = x_full[319:288];
        y = y_full[319:288];
        #10;

        // Then LSB part
        x = x_full[287:256];
        y = y_full[287:256];
        #10;




        x = x_full[255:224];
        y = y_full[255:224];
        #10;
        x = x_full[224:192];
        y = y_full[224:192];
        #10;
        x = x_full[191:160];
        y = y_full[191:160];
        #10;
        x = x_full[159:128];
        y = y_full[159:128];
        #10;
        x = x_full[127:96];
        y = y_full[127:96];
        #10;

        x = x_full[95:64];
        y = y_full[95:64];
        #10;

        // Feed MSB part first
        x = x_full[63:32];
        y = y_full[63:32];
        #10;

        // Then LSB part
        x = x_full[31:0];
        y = y_full[31:0];
        #10;
        // x = x_full[511:448];
        // y = y_full[511:448];
        // #10;
        // x = x_full[447:384];
        // y = y_full[447:384];
        // #10;
        // x = x_full[383:320];
        // y = y_full[383:320];
        // #10;
        // x = x_full[319:256];
        // y = y_full[319:256];
        // #10;
        // x = x_full[255:192];
        // y = y_full[255:192];
        // #10;
        // x = x_full[191:128];
        // y = y_full[191:128];
        // #10;
        // x = x_full[127:64];
        // y = y_full[127:64];
        // #10;
        // x = x_full[63:0];
        // y = y_full[63:0];
        // #10;

        // Hold inputs at 0
        x = 0;
        y = 0;

        // Wait and print outputs
        #500;

        expected_result = x_full * y_full;
        $display("Expected result: %h", expected_result);
        $display("Output slice (out): %h", out);  // Prints 32-bit chunks
        $display("%h", dut.outf);
        #100;
        $finish;
    end
    initial begin
        $dumpfile("karatsuba_top_r.vcd");
        $dumpvars(0, dut);
    end

endmodule
