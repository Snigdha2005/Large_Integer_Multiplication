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

module generic_base_multiplier #(parameter base_mult = 10)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] y1,
    input [base_mult-1:0] x2,
    input [base_mult-1:0] y2,
    input a_in,
    input b_in,
    output reg [2*base_mult:0] out
);
    always @(*) begin
        out = (a_in == 0)? ((b_in == 0) ? x1 * y1 : x1 * y2) : ((b_in == 0) ? x2 * y1 : x2 * y2);
    end
endmodule

module generic_multiplier #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 65536)(
    input clk,
    input int size,
//    output reg done
    output reg [interface_bits-1:0] out
    );
    
    int num_blocks;

    assign num_blocks = size / interface_bits;

    int prev_size ;
    reg [15:0] addra[0:1];
    reg [interface_bits-1:0] dina[0:1];
    reg [interface_bits-1:0] douta[0:1];
    
    reg [15:0] addrb[0:1];
    reg [interface_bits-1:0] dinb[0:1];
    reg [interface_bits-1:0] doutb[0:1];
    reg ena = 1'b1;
    reg ena1 = 1'b1;

    int p_a_idx = 0;
    int p_b_idx = 0;
    reg a_in;
    reg b_in;
    reg [31:0] shift_pipe1, shift_pipe3;
    reg [2*base_mult:0] mult_pipe, mult_result;

    reg accumulation_done;
    reg [2*bram_depth*interface_bits:0] final_out = 0;
    
    generic_base_multiplier #(base_mult) dut(.clk(clk), .x1(douta[0]), .y1(doutb[0]), .x2(douta[1]), .y2(doutb[1]), .a_in(a_in), .b_in(b_in), .out(mult_result));
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

    int count = 0;
    int a_idx = 0;
    int b_idx = 0;

    always @(posedge clk) begin
        prev_size <= size;
    end    
    always @(posedge clk) begin
        if(prev_size == size || count == 0) begin
        if(a_idx == 0) begin
            addra[0] <= 32'b0;
            a_idx <= a_idx + 1;
        end
        else if (a_idx == 1) begin
            addra[1] <= 32'b0;
            a_idx <= a_idx + 1;
        end
        else if ((a_idx < num_blocks-1) && (a_idx > 1)) begin
            if (a_idx % 2 == 0) begin
                addra[0] <= addra[0] + 1;
            end
            else if (a_idx % 2 == 1) begin
                addra[1] <= addra[1] + 1;
            end
            a_idx <= a_idx + 1;
        end
        else if ((a_idx == num_blocks-1) && (a_idx > 1)) begin
            addra[1] <= addra[1] + 1;
            a_idx <= 0;
        end

        if (b_idx == 0) begin
            addrb[0] <= 32'b0;
            b_idx <= b_idx + 1;
        end
        else if (b_idx == 1 && (a_idx == num_blocks-2)) begin
            addrb[1] <= 32'b0;
            b_idx <= b_idx + 1;
        end
        else if ((b_idx < num_blocks) && (a_idx == num_blocks-2) && (b_idx > 1)) begin
            if (b_idx % 2 == 0) begin
                addrb[0] <= addrb[0] + 1;
            end
            else if (b_idx % 2 == 1) begin
                addrb[1] <= addrb[1] + 1;
            end
            b_idx <= b_idx + 1;
        end
        count <= count + 1;
        end
        else begin
            count <= 0;
            a_idx <= 0;
            b_idx <= 0;
            addra[0] <= 0;
            addra[0] <= 0;
            addrb[1] <= 0;
            addrb[1] <= 0;
        end
    end

    always @(posedge clk) begin
        if(prev_size == size || count == 0) begin
        if (count >= 2) begin
            if ((p_a_idx <= num_blocks-1) && (p_b_idx <= num_blocks-1)) begin
                a_in = (p_a_idx % 2 == 0)? 1'b0:1'b1;
                b_in = (p_b_idx % 2 == 0)? 1'b0:1'b1;
                shift_pipe1 <= base_mult * (p_a_idx + p_b_idx);
                if (p_a_idx == num_blocks-1) begin
                    p_a_idx <= 0;
                    p_b_idx <= p_b_idx + 1;
                end
                else if (p_a_idx < num_blocks-1) begin
                    p_a_idx <= p_a_idx + 1;
                    p_b_idx <= p_b_idx;
                end
            end
        end
        end
        else begin
            p_a_idx <= 0;
            p_b_idx <= 0;
            a_in = 0;
            b_in = 0;
        end
    end

    always @(posedge clk) begin
        if (prev_size == size || count == 0) begin
        shift_pipe3 <= shift_pipe1;
        mult_pipe <= mult_result;
        // $display("mult_result %d", mult_result);
        // $display("mult_pipe %d, shift_pipe3 %d", mult_pipe, shift_pipe3);
        end
    end

    integer step_counter = 0;
    always @(posedge clk) begin
        if(prev_size == size) begin
        if ((count >= 4) && (step_counter < num_blocks*num_blocks)) begin
            final_out <= final_out + (mult_pipe << shift_pipe3);
            // $display("mult_pipe %d, shift_pipe3 %d", mult_pipe, shift_pipe3);
            step_counter <= step_counter + 1;
        end else if (step_counter == num_blocks*num_blocks) begin
            accumulation_done <= 1;
        end
        end
        else begin
            step_counter <= 0;
            accumulation_done <= 0;
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