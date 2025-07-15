`timescale 1ns / 1ps
// bram.v
module a (
    input wire clka,
    input wire ena,
    input wire wea,
    input wire [15:0] addra,
    input wire [31:0] dina,
    output reg [31:0] douta
);
    reg [31:0] mem [0:3];  // 64K x 32-bit

    always @(posedge clka) begin
        if (ena) begin
            if (wea)
                mem[addra] <= dina;
            douta <= mem[addra];
        end
    end
endmodule

module karatsuba_recursive #(
    parameter num_bits = 64,
    parameter NUM_LEVELS = 0,
    parameter MAX_LEVELS = 4
)(
    input start,
    input  wire [num_bits-1:0] x,
    input  wire [num_bits-1:0] y,
    output wire [2*num_bits-1:0] out
);

generate
    if (MAX_LEVELS < NUM_LEVELS) begin : base_case
        assign out = (start == 1)? x * y: 0;
    end else begin : recurse
        localparam fh = num_bits / 2;
        localparam sh = num_bits - fh;

        wire [fh-1:0] x0 = x[fh-1:0];
        wire [sh-1:0] x1 = x[num_bits-1:fh];
        wire [fh-1:0] y0 = y[fh-1:0];
        wire [sh-1:0] y1 = y[num_bits-1:fh];

        // Sign-extend or zero-extend smaller part before addition
        wire [sh:0] x0_ext = {{(sh - fh + 1){1'b0}}, x0};
        wire [sh:0] y0_ext = {{(sh - fh + 1){1'b0}}, y0};

        wire [sh:0] sum_x = x1 + x0_ext;
        wire [sh:0] sum_y = y1 + y0_ext;

        wire [2*fh-1:0] out_p1;
        wire [2*sh-1:0] out_p2;
        wire [2*(sh+1)-1:0] out_p3;

        karatsuba_recursive #(fh, NUM_LEVELS+1, MAX_LEVELS) p1(.x(x0), .y(y0), .out(out_p1), .start(start));
        karatsuba_recursive #(sh, NUM_LEVELS+1, MAX_LEVELS) p2(.x(x1), .y(y1), .out(out_p2), .start(start));
        karatsuba_recursive #(sh+1, NUM_LEVELS+1, MAX_LEVELS) p3(.x(sum_x), .y(sum_y), .out(out_p3), .start(start));

        // Promote operands to same width before arithmetic
        wire [2*(sh+1)-1:0] p2_ext = {{(2*(sh+1)-2*sh){1'b0}}, out_p2};
        wire [2*(sh+1)-1:0] p1_ext = {{(2*(sh+1)-2*fh){1'b0}}, out_p1};

        wire [2*(sh+1)-1:0] middle = out_p3 - p2_ext - p1_ext;

        wire [2*num_bits-1:0] part1 = {{(2*num_bits - 2*sh){1'b0}}, out_p2} << (2*fh);
        wire [2*num_bits-1:0] part2 = {{(2*num_bits - 2*(sh+1)){1'b0}}, middle} << fh;
        wire [2*num_bits-1:0] part3 = {{(2*num_bits - 2*fh){1'b0}}, out_p1};

        assign out = (start == 1) ? part1 + part2 + part3 : 0;
    end
endgenerate
endmodule

module generic_multiplier #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 65536, parameter MAX_LEVELS = 3)(
    input clk,
    input int size,
//    output reg done
    output reg [interface_bits-1:0] out
    );
    int num_clocks;
    localparam wait_clocks = base_mult / interface_bits;
    int num_blocks;
    
    reg [15:0] addra[0:1];
    reg [interface_bits-1:0] dina[0:1];
    reg [interface_bits-1:0] douta[0:1];
    
    reg [15:0] addrb[0:1];
    reg [interface_bits-1:0] dinb[0:1];
    reg [interface_bits-1:0] doutb[0:1];
    
//    reg [15:0] addrout = 1'b0;
//    reg [interface_bits-1:0] dinout;
//    reg [interface_bits-1:0] doutout;
    reg ena = 1'b1;
    reg ena1 = 1'b1;
    a a1 (
      .clka(clk),    // input wire clka
      .ena(ena), 
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(addra[0]),  // input wire [15 : 0] addra
      .dina(dina[0]),    // input wire [31 : 0] dina
      .douta(douta[0])  // output wire [31 : 0] douta
    );
    a a2 (
      .clka(clk),    // input wire clka
      .ena(ena1), 
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(addra[1]),  // input wire [15 : 0] addra
      .dina(dina[1]),    // input wire [31 : 0] dina
      .douta(douta[1])  // output wire [31 : 0] douta
    );
    a b1 (
      .clka(clk),    // input wire clka
      .ena(ena), 
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(addrb[0]),  // input wire [15 : 0] addra
      .dina(dinb[0]),    // input wire [31 : 0] dina
      .douta(doutb[0])  // output wire [31 : 0] douta
    );
    a b2 (
      .clka(clk),    // input wire clka
      .ena(ena1), 
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(addrb[1]),  // input wire [15 : 0] addra
      .dina(dinb[1]),    // input wire [31 : 0] dina
      .douta(doutb[1])  // output wire [31 : 0] douta
    );
//    a total_output (
//      .clka(clk),    // input wire clka
//      .wea(1'b1),      // input wire [0 : 0] wea
//      .addra(addrout),  // input wire [15 : 0] addra
//      .dina(dinout),    // input wire [64 : 0] dina
//      .douta(doutout)  // output wire [64 : 0] douta
//    );
    int count = 0;
    reg [base_mult-1:0] a;
    reg [base_mult-1:0] b;
    
    int a_idx = 1;
    int b_idx = 1;
    
    reg [31:0] shift_pipe1, shift_pipe3;
    reg [2*base_mult:0] mult_pipe, mult_result;
    reg accumulation_done;
    reg [2*bram_depth*interface_bits:0] final_out = 0;
    
    assign num_clocks = size / interface_bits;
    assign num_blocks = size / base_mult;
    reg [base_mult-1:0] in1, in2;
    karatsuba_recursive #(base_mult, 0, MAX_LEVELS) dut(.start(1'b1), .x(in1), .y(in2), .out(mult_result));
    always @(posedge clk)begin
        if(count % 2 == 1 && count < num_clocks && (num_clocks > 1)) begin
            if (count > 1) begin
                // ena <= 1'b1;
                addra[0] <= addra[0] + 1;
                addrb[0] <= addrb[0] + 1;
                // $display("adding 1 a1");
                // ena <= 1'b1;
            end
            else if (count == 1) begin
                // ena <= 1'b1;
                addra[0] <= 32'b0;
                addrb[0] <= 32'b0;
                // $display("default");
            end
        end
        else if ((count % 2 == 0) && (count <= num_clocks) && (num_clocks > 1))begin
            if(count > 2)begin
                // ena1 <= 1'b1;
                addra[1] <= addra[1] + 1;
                addrb[1] <= addrb[1] + 1;
                // $display("adding 1 a2");
            end
            else if (count == 2) begin
                // ena1 <= 1'b1;
                addra[1] <= 32'b0;
                addrb[1] <= 32'b0;
                // $display("default a2");
            end
            // $display("count = %d, num_clocks = %d", count, num_clocks);
        end
        else if (count % 2 == 1 && num_clocks <= 1) begin
            // ena <= 1'b1;
            addra[0] <= 32'b0;
            addrb[0] <= 32'b0;
        end
        // else if (count > (num_clocks + 3)) begin
        //     ena <= 1'b0;
        //     ena1 <= 1'b0;
        //     $display("enable");
        // end
        // $display("count = %d, num_clocks = %d", count, num_clocks);
        count <= count + 1;
    end
    int p_idx = 0;
    reg [base_mult-1:0] a_in [0:(bram_depth*interface_bits/base_mult)-1];
    reg [base_mult-1:0] b_in [0:(bram_depth*interface_bits/base_mult)-1];
    
    always @(posedge clk) begin
        if (num_clocks > 1) begin
            if(count % 2 == 0 && count < (num_clocks + 4) && count >= 3) begin
                if (wait_clocks > 1) begin
                    a <= {a, douta[0]};
                    b <= {b, doutb[0]};
                end
                else if (wait_clocks == 1) begin
                    a <= douta[0];
                    b <= doutb[0];
                end
            end
            else if(count % 2 == 1 && count < (num_clocks + 4) && count >= 4) begin
                if (wait_clocks > 1) begin
                    a <= {a, douta[1]};
                    b <= {b, doutb[1]};
                end
                else if (wait_clocks == 1) begin
                    a <= douta[1];
                    b <= doutb[1];
                end 
            end
        end
        else begin
            if (count == 4) begin
                a <= {1'b0, douta[0]};
                b <= {1'b0, doutb[0]};
            end
        end
    end
    
    always @(posedge clk)begin
        if(count >= 5 && count < (num_clocks + 5))begin
            a_in[p_idx] <= a;
            b_in[p_idx] <= b;
            p_idx <= p_idx + 1;
        end
    end
    always @(posedge clk) begin
        if((a_idx <= (num_blocks)) && (b_idx <= (num_blocks)) && num_clocks > 1)begin
            if (count >= 6) begin
                in1 <= a_in[(a_idx-1)];
                in2 <= b_in[(b_idx-1)];
                shift_pipe1 <= base_mult * (a_idx + b_idx - 2);
                // $display("in1 = %d, in2 = %d", in1, in2);
                if (a_idx == (num_blocks)) begin
                    a_idx <= 1;
                    b_idx <= b_idx + 1;
                end
                else if (a_idx < (num_blocks)) begin
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx;
                end
            end
        end
    end
    
    always @(posedge clk) begin
        shift_pipe3 <= shift_pipe1;
        mult_pipe <= mult_result;
        // $display("mult pipe = %d, shift_pipe3 = %d", mult_pipe, shift_pipe3);
    end
    
    integer step_counter = 0;
    always @(posedge clk) begin
        if ((count >= 8) && (step_counter < num_blocks*num_blocks) && (num_clocks > 1)) begin
            final_out <= final_out + (mult_pipe << shift_pipe3);
            step_counter <= step_counter + 1;
        //    $display("step counter =  %d, num_steps = %h", step_counter, final_out);
        end else if (step_counter == num_blocks*num_blocks) begin
//            final_out <= final_out;
//            done <= 1;
            accumulation_done <= 1;
        end
        else if (num_clocks <= 1 && count >= 5) begin
            final_out <= mult_pipe;
//            done <= 1;
            accumulation_done <= 1;
        end
    end
    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if (accumulation_done && out_idx < 2*size) begin
            out <= final_out[out_idx +: interface_bits];
            out_idx <= out_idx + interface_bits;
        end
    end
endmodule
