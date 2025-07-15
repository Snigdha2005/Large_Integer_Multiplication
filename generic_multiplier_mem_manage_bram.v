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

module out (
    input wire clka,
    input wire ena,
    input wire wea,
    input wire [15:0] addra,
    input wire [63:0] dina,
    output reg [63:0] douta,

    input wire clkb,
    input wire enb,
    input wire web,
    input wire [15:0] addrb,
    input wire [63:0] dinb,
    output reg [63:0] doutb
);

    reg [63:0] mem [0:6];  // 64K-depth dual-port 128-bit memory

    always @(posedge clka) begin
        if (ena) begin
            if (wea)
                mem[addra] <= dina;
            douta <= mem[addra];
        end
    end

    always @(posedge clkb) begin
        if (enb) begin
            if (web)
                mem[addrb] <= dinb;
            doutb <= mem[addrb];
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

    int prev_size;
    reg [15:0] addra[0:1];
    reg [interface_bits-1:0] dina[0:1];
    reg [interface_bits-1:0] douta[0:1];
    
    reg [15:0] addrb[0:1];
    reg [interface_bits-1:0] dinb[0:1];
    reg [interface_bits-1:0] doutb[0:1];
    reg ena2 = 1'b1;
    reg ena1 = 1'b1;

    int p_a_idx = 0;
    int p_b_idx = 0;
    reg a_in;
    reg b_in;
    reg [31:0] shift_pipe1, shift_pipe2, shift_pipe3;
    reg [2*base_mult:0] mult_pipe, mult_result, mult_pipe2;

    // reg accumulation_done;
    // reg [2*bram_depth*interface_bits:0] final_out = 0;
    
    generic_base_multiplier #(base_mult) dut(.clk(clk), .x1(douta[0]), .y1(doutb[0]), .x2(douta[1]), .y2(doutb[1]), .a_in(a_in), .b_in(b_in), .out(mult_result));
    a a1 (
      .clka(clk),    // input wire clka
      .ena(ena2), 
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
      .ena(ena2), 
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

    reg [2*bram_depth-2:0] carry = 0;

    reg ena = 1'b1;
    reg wea = 1'b0;
    wire [2*base_mult-1:0] addrouta;
    wire [2*base_mult-1:0] addroutb;

    reg [2*base_mult-1:0] addrouta1;
    reg [2*base_mult-1:0] addroutb1;
    reg [2*base_mult-1:0] addrouta2;
    reg [2*base_mult-1:0] addroutb2;
    
    reg [2*base_mult:0] dinouta;
    reg [2*base_mult:0] dinoutb;
    reg [2*base_mult:0] doutouta;
    reg [2*base_mult :0] doutoutb;
    
    reg enb = 1'b1;
    reg web = 1'b1;

    int count = 0;
    int a_idx = 0;
    int b_idx = 0;
    
    reg accumulation_done = 1'b0;

    assign addrouta = (accumulation_done == 1'b1)? addrouta2:addrouta1;
    assign addroutb = (accumulation_done == 1'b1)? addroutb2:addroutb1;

    out final_out (
    .clka(clk),    // input wire clka
    .ena(ena),      // input wire ena
    .wea(wea),      // input wire [0 : 0] wea
    .addra(addrouta),  // input wire [1 : 0] addra
    .dina(dinouta),    // input wire [127 : 0] dina
    .douta(doutouta),  // output wire [127 : 0] douta
    .clkb(clk),    // input wire clkb
    .enb(enb),      // input wire enb
    .web(web),      // input wire [0 : 0] web
    .addrb(addroutb),  // input wire [1 : 0] addrb
    .dinb(dinoutb),    // input wire [127 : 0] dinb
    .doutb(doutoutb)  // output wire [127 : 0] doutb
    );

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
                shift_pipe1 <= (p_a_idx + p_b_idx);
                addrouta1 <= (p_a_idx + p_b_idx);
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
            addrouta1 <= 0;
            a_in = 0;
            b_in = 0;
        end
    end

    // reg [2*interface_bits-1:0] doutouta_pipe1, doutouta_pipe2;

    always @(posedge clk) begin
        if (prev_size == size || count == 0) begin
            shift_pipe2 <= shift_pipe1;
            mult_pipe <= mult_result;
        end
    end

    always @(posedge clk) begin
        if (prev_size == size || count == 0) begin
        shift_pipe3 <= shift_pipe2;
        mult_pipe2 <= mult_pipe;
        // doutouta_pipe1 <= doutouta;       // 1st cycle after address
        // doutouta_pipe2 <= doutouta_pipe1; // 2nd cycle → now valid
        end
    end

    always @(posedge clk) begin
        // shift_pipe3 <= shift_pipe2;
        if(prev_size == size) begin
        if (count >= 5 && count - 5 <= num_blocks*num_blocks)begin
            if(shift_pipe3 == 0) begin
                {carry[shift_pipe3], dinoutb} <= doutouta + mult_pipe2;
                addroutb1 <= shift_pipe3;
            end
            else begin
                {carry[shift_pipe3], dinoutb} <= doutouta + mult_pipe2 + {1'b0, carry[shift_pipe3-1]};
                addroutb1 <= shift_pipe3;
                carry[shift_pipe3-1] <= 1'b0;
            end
        end
        else if (count - 5 > num_blocks*num_blocks) begin
            accumulation_done <= 1'b1;
        end
        end
        else begin
            addroutb1 <= 0;
            accumulation_done <= 0;
        end
    end

    // reg start = 1'b0;

    // always @(posedge clk)begin
    //     if(accumulation_done && count == num_blocks*num_blocks+6 && num_blocks != 1) begin
    //         addrouta2 <= 1'b0;
    //         addroutb2 <= 1'b1;
    //         // start <= 1'b0;
    //     end
    //     else if (accumulation_done && count == num_blocks*num_blocks+6 && num_blocks == 1)begin
    //         addrouta2 <= 1'b0;
    //     end
    //     else if(accumulation_done && (addroutb2 + 2 < 2*num_blocks)) begin
    //         addrouta2 <= addrouta2 + 1;
    //         addroutb2 <= addroutb2 + 1;
    //         // start <= 1'b1;
    //     end
    //     else if(accumulation_done && (addrouta2 + 2 < 2*num_blocks))begin
    //         addrouta2 <= addrouta2 + 1;
    //     end
    // end

    // reg c = 1'b0;
    // always @(posedge clk) begin
    //     if(count == num_blocks*num_blocks+8 && accumulation_done && num_blocks != 1)begin
    //         {c, out} <= {doutoutb[base_mult-1:0] + doutouta[2*base_mult]} 
    //     end
    // end
endmodule
