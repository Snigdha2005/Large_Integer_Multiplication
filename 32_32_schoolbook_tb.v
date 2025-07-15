module test_bench;
    parameter base_mult = 64;
    parameter size = 2048; // for 2 blocks

    reg clk;
    reg [base_mult-1:0] x1;
    reg [base_mult-1:0] y1;
    
    reg [base_mult-1:0] x2;
    reg [base_mult-1:0] y2;
    wire [base_mult-1:0] out;
    wire valid_out;

    // Instantiate the module
    BRAM_4_1_grp_multiplier #(base_mult, size) dut (
        .clk(clk),
        .x1(x1),
        .x2(x2),
        .y1(y1),
        .y2(y2),
        .out(out),
        .valid_out(valid_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        // Initialize inputs
        x1 = 32'd9;
        y1 = 32'd12;

        x2 = 32'd00;
        y2 = 32'd00;

        #10;
        x1 = 32'd00;
        y1 = 32'd00;

        x2 = 32'd00;
        y2 = 32'd00;        
        
        #10;
        x1 = 32'd00;
        y1 = 32'd00;

        x2 = 32'd00;
        y2 = 32'd00;
        #10;
        x1 = 32'd00;
        y1 = 32'd00;

        #10;
        x1 = 32'd00;
        y1 = 32'd00;

        x2 = 32'd00;
        y2 = 32'd00;
        #10;
        x1 = 32'd00;
        y1 = 32'd00;

        #10;
        x1 = 32'd00;
        y1 = 32'd00;
        x2 = 32'd00;
        y2 = 32'd00;
        // #10;
        // x1 = 32'd00;
        // y1 = 32'd00;

        #10;
        x1 = 32'd00;
        y1 = 32'd00;

        x2 = 32'd00;
        y2 = 32'd00;
        // #10;
        // x1 = 32'd00;
        // y1 = 32'd00;

        #10;
        x1 = 32'd00;
        y1 = 32'd00;
        x2 = 32'd00;
        y2 = 32'd00;
        // #10;
        // x1 = 32'd00;
        // y1 = 32'd00;

        #10;
        x1 = 32'd00;
        y1 = 32'd00;
        x2 = 32'd00;
        y2 = 32'd00;
        // x2 = 32'hCCCC_CCCC; // should not be stored (num_blocks=2)
        // y2 = 32'h3333_3333;

        #90000;

        $display("out =  %d", out);
        $finish;
    end

    initial begin
        $dumpfile("check.vcd");
        // $dumpvars(0, dut, dut.a[0], dut.a[1], dut.b[0], dut.b[1], dut.partial_out[0], dut.shift_amount[0], dut.partial_out[1], dut.shift_amount[1], dut.partial_out[2], dut.shift_amount[2],  dut.partial_out[3], dut.shift_amount[3],dut.in1, dut.in2, dut.outf);
        $dumpvars(0, dut, dut.a[0], dut.a[1], dut.b[0], dut.b[1], dut.shift_pipe1, dut.shift_pipe2, dut.mult_pipe, dut.in1, dut.in2, dut.final_out);
    end

    initial begin
        $monitor("total_out =  %h", out);
    end
endmodule