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
    reg [31:0] mem [0:65535];  // 64K x 32-bit

    always @(posedge clka) begin
        if (ena) begin
            if (wea)
                mem[addra] <= dina;
            douta <= mem[addra];
        end
    end
endmodule

module generic_base_multiplier #(parameter base_mult = 10)(
    // input clk,
    input [base_mult-1:0] x,
    input [base_mult-1:0] y,
    output reg [2*base_mult:0] out
);
    always @(*) begin
        out = x * y;
    end
endmodule

module generic_multiplier #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 65536)(
    input clk,
    input int size,
//    output reg done
    output reg [interface_bits-1:0] out
    );
    int num_clocks;
    localparam wait_clocks = 2 * base_mult / interface_bits;
    int num_blocks;
    
    int prev_size;
    reg [15:0] addra;
    reg [interface_bits-1:0] dina;
    reg [interface_bits-1:0] douta;
    
    reg [15:0] addrb;
    reg [interface_bits-1:0] dinb;
    reg [interface_bits-1:0] doutb;
    
    reg ena = 1'b1;
    reg ena1 = 1'b1;
    a a1 (
      .clka(clk),    // input wire clka
      .ena(ena), 
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(addra),  // input wire [15 : 0] addra
      .dina(dina),    // input wire [31 : 0] dina
      .douta(douta)  // output wire [31 : 0] douta
    );
    a b1 (
      .clka(clk),    // input wire clka
      .ena(ena), 
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(addrb),  // input wire [15 : 0] addra
      .dina(dinb),    // input wire [31 : 0] dina
      .douta(doutb)  // output wire [31 : 0] douta
    );
    int count = 0;
    reg [base_mult-1:0] a;
    reg [base_mult-1:0] b;
    
    int a_idx = 1;
    int b_idx = 1;
    
    reg [31:0] shift_pipe1, shift_pipe3;
    reg [2*base_mult:0] mult_pipe, mult_result;
    reg accumulation_done;
    reg [2*bram_depth*interface_bits:0] final_out = 0;
    
    assign num_clocks = 2 * size / interface_bits;
    assign num_blocks = size / base_mult;
    reg [base_mult-1:0] in1, in2;
    generic_base_multiplier #(base_mult) dut(.x(in1), .y(in2), .out(mult_result));
    
    always @(posedge clk) begin
        prev_size <= size;
    end

    always @(posedge clk)begin
        if(prev_size == size || count == 0) begin
        if(count % 2 == 1 && count < num_clocks && (num_clocks > 1)) begin
            if (count > 1) begin
                // ena <= 1'b1;
                addra <= addra + 1;
                addrb <= addrb + 1;
                // $display("adding 1 a1");
                // ena <= 1'b1;
            end
            else if (count == 1) begin
                // ena <= 1'b1;
                addra <= 32'b0;
                addrb <= 32'b0;
                // $display("default");
            end
        end
        else if (count % 2 == 1 && num_clocks <= 1) begin
            // ena <= 1'b1;
            addra <= 32'b0;
            addrb <= 32'b0;
        end
        count <= count + 1;
        end
        else begin
            count <= 0;
            addra <= 0;
            addrb <= 0;
        end
    end
    int p_idx = 0;
    reg [base_mult-1:0] a_in [0:(bram_depth*interface_bits/base_mult)-1];
    reg [base_mult-1:0] b_in [0:(bram_depth*interface_bits/base_mult)-1];
    
    always @(posedge clk) begin
        if(prev_size == size) begin
        if (num_clocks > 1) begin
            if(count % 2 == 0 && count < (num_clocks + 4) && count >= 3) begin
                if (wait_clocks > 1) begin
                    a <= {a, douta};
                    b <= {b, doutb};
                end
                else if (wait_clocks == 1) begin
                    a <= douta;
                    b <= doutb;
                end
            end
        end
        else begin
            if (count == 4) begin
                a <= {1'b0, douta};
                b <= {1'b0, doutb};
            end
        end
        end
        else begin
            a <= 0;
            b <= 0;
        end
    end
    
    always @(posedge clk)begin
        if(prev_size == size) begin
        if(count >= 5 && count < (num_clocks + 5) && count % 2 == 0)begin
            a_in[p_idx] <= a;
            b_in[p_idx] <= b;
            p_idx <= p_idx + 1;
        end
        end
        else begin
            p_idx <= 0;
        end
    end
    always @(posedge clk) begin
        if(prev_size == size) begin
        if((a_idx <= (num_blocks)) && (b_idx <= (num_blocks)) && num_clocks > 1)begin
            if (count >= 9 && count % 2 == 0) begin
                in1 <= a_in[(a_idx-1)];
                in2 <= b_in[(b_idx-1)];
                shift_pipe1 <= base_mult * (a_idx + b_idx - 2);
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
        else begin
            a_idx <= 0;
            b_idx <= 0;
        end
    end
    
    always @(posedge clk) begin
        if(prev_size == size) begin
        shift_pipe3 <= shift_pipe1;
        mult_pipe <= mult_result;
        end
    end

    // always @(posedge clk) begin
    //     shift_pipe3 <= shift_pipe2;
    // end
    
    integer step_counter = 0;
    always @(posedge clk) begin
        if(prev_size == size) begin
        if ((count >= 12) && (step_counter < num_blocks*num_blocks) && (num_clocks > 1)) begin
            final_out <= final_out + (mult_pipe << shift_pipe3);
            step_counter <= step_counter + 1;
        end else if (step_counter == num_blocks*num_blocks) begin
            accumulation_done <= 1;
        end
        else if (num_clocks <= 1 && count >= 5) begin
            final_out <= mult_pipe;
            accumulation_done <= 1;
        end
        end
        else begin
            accumulation_done <= 0;
            step_counter <= 0;
        end
    end
    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if(prev_size == size) begin
        if (accumulation_done && out_idx < 2*size) begin
            out <= final_out[out_idx +: interface_bits];
            out_idx <= out_idx + interface_bits;
        end
        end
        else begin
            out_idx <= 0;
        end
    end
endmodule

// module top #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 4)(
//     input clk,
//     output reg [interface_bits-1:0] out
// );
//     int size = 128;
//     generic_multiplier #(base_mult, interface_bits, bram_depth) check(clk, size, out);    
    
// endmodule