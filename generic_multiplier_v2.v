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
    input clk,
    input [base_mult-1:0] x,
    input [base_mult-1:0] y,
    output reg [2*base_mult:0] out
);
    always @(posedge clk) begin
        out <= x * y;
    end
endmodule

module generic_multiplier #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 65536)(
    input clk,
    input int size,
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
    
    assign num_clocks = size / interface_bits;
    assign num_blocks = size / base_mult;
    int count = 0;
    reg [9:0] a_alt_arr;
    reg [9:0] b_alt_arr;
    reg [base_mult-1:0] a;
    reg [base_mult-1:0] b;
    int a_idx = 1;
    int b_idx = 1;
    reg a_alt = 0;
    reg b_alt = 0;
    reg [31:0] shift_pipe1, shift_pipe2, shift_pipe3, shift_pipe4;
    reg [2*base_mult:0] mult_pipe, mult_result;

    generic_base_multiplier #(base_mult) dut(.clk(clk), .x(a), .y(b), .out(mult_result));

    always @(posedge clk) begin
        if (wait_clocks == 1) begin
            if (a_idx <= num_blocks && b_idx <= num_blocks) begin
                if ((a_idx == num_clocks - 2) && (a_alt == 0) && (b_alt == 0))begin
                    addra[0] <= addra[0] + 1;
                    addrb[0] <= addrb[0] + 1;
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx + 1;
                    a_alt <= 1'b1;
                    b_alt <= 1'b1;
                    a_alt_arr <= {a_alt_arr, a_alt};
                    b_alt_arr <= {b_alt_arr, b_alt};
                end 
                else if ((a_idx == num_clocks - 2) && (a_alt == 1) && (b_alt == 1))begin
                    addra[1] <= addra[1] + 1;
                    addrb[1] <= addrb[1] + 1;
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx + 1;
                    a_alt <= 1'b0;
                    b_alt <= 1'b0;
                    a_alt_arr <= {a_alt_arr, a_alt};
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                else if ((a_idx == num_clocks - 2) && (a_alt == 1) && (b_alt == 0))begin
                    addra[1] <= addra[1] + 1;
                    addrb[0] <= addrb[0] + 1;
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx + 1;
                    a_alt <= 1'b0;
                    b_alt <= 1'b1;
                    a_alt_arr <= {a_alt_arr, a_alt};
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                else if ((a_idx == num_clocks - 2) && (a_alt == 0) && (b_alt == 1))begin
                    addra[0] <= addra[0] + 1;
                    addrb[1] <= addrb[1] + 1;
                    a_idx <= a_idx + 1;
                    b_idx <= b_idx + 1;
                    a_alt <= 1'b1;
                    b_alt <= 1'b0;
                    a_alt_arr <= {a_alt_arr, a_alt};
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                else if ((a_idx != num_clocks - 2) && (a_alt == 0))begin
                    addra[0] <= (a_idx == num_clocks)?1'b0:addra[0] + 1;
                    a_idx <= (a_idx == num_clocks)?1:a_idx + 1;
                    a_alt <= 1'b1;
                    b_alt <= b_alt;
                    a_alt_arr <= {a_alt_arr, a_alt};
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                else if ((a_idx != num_clocks - 2) && (a_alt == 1))begin
                    addra[1] <= (a_idx == num_clocks)?1'b0:addra[1] + 1;
                    a_idx <= (a_idx == num_clocks)?1:a_idx + 1;
                    a_alt <= 1'b1;
                    b_alt <= b_alt;
                    a_alt_arr <= {a_alt_arr, a_alt};
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                
                if (a_idx == 1 && a_alt == 0) begin
                    addra[0] <= 1'b0;
                    a_idx <= a_idx + 1;
                    a_alt <= 1'b1;
                    a_alt_arr <= {a_alt_arr, a_alt};
                end
                else if (a_idx == 1 && a_alt == 1)begin
                    addra[1] <= 1'b0;
                    a_idx <= a_idx + 1;
                    a_alt <= 1'b0;
                    a_alt_arr <= {a_alt_arr, a_alt};
                end
                else if (a_idx == 2 && a_alt == 0)begin
                    addra[0] <= 1'b0;
                    a_idx <= a_idx + 1;
                    a_alt <= 1'b1;
                    a_alt_arr <= {a_alt_arr, a_alt};
                end
                else if (a_idx == 2 && a_alt == 1)begin
                    addra[1] <= 1'b0;
                    a_idx <= a_idx + 1;
                    a_alt <= 1'b0;
                    a_alt_arr <= {a_alt_arr, a_alt};
                end

                if (b_idx == 1 && b_alt == 0) begin
                    addrb[0] <= 1'b0;
                    b_idx <= b_idx + 1;
                    b_alt <= 1'b1;
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                else if (b_idx == 1 && b_alt == 1)begin
                    addrb[1] <= 1'b0;
                    b_idx <= b_idx + 1;
                    b_alt <= 1'b0;
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                else if (b_idx == 2 && b_alt == 0)begin
                    addrb[0] <= 1'b0;
                    b_idx <= b_idx + 1;
                    b_alt <= 1'b1;
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                else if (b_idx == 2 && b_alt == 1)begin
                    addrb[1] <= 1'b0;
                    b_idx <= b_idx + 1;
                    b_alt <= 1'b0;
                    b_alt_arr <= {b_alt_arr, b_alt};
                end
                shift_pipe1 <= base_mult * (a_idx + b_idx - 2);
            end
        end
        count <= count + 1;
    end
    reg p_a_alt = 0;
    reg p_b_alt = 0;
    int step_counter = 0;
    always @(posedge clk)begin
        if (wait_clocks == 1) begin
            if(count >= 2 && step_counter < num_blocks*num_blocks)begin
                a <= (p_a_alt == 0)?douta[1]:douta[0];
                b <= (p_b_alt == 0)?doutb[1]:doutb[0];
                p_a_alt <= (~p_a_alt);
                p_b_alt <= (~p_b_alt);
                step_counter <= step_counter + 1;
                shift_pipe2 <= shift_pipe1;
            end
        end
    end
    always @(posedge clk) begin
        shift_pipe3 <= shift_pipe2;
        mult_pipe <= mult_result;
    end

    always @(posedge clk) begin
        shift_pipe4 <= shift_pipe3;
    end


endmodule

module top #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 4)(
    input clk,
    output reg [interface_bits-1:0] out
);
    int size = 128;
    generic_multiplier #(base_mult, interface_bits, bram_depth) check(clk, size, out);    
    
endmodule