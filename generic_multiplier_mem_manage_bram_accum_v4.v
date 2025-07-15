`timescale 1ns / 1ps
// bram.v
module a (
    input wire clka,
    input wire ena,
    input wire wea,
    input wire [3:0] addra,
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
    input wire [6:0] addra,
    input wire [66:0] dina,
    output reg [66:0] douta,

    input wire clkb,
    input wire enb,
    input wire web,
    input wire [6:0] addrb,
    input wire [66:0] dinb,
    output reg [66:0] doutb
);

    reg [66:0] mem [0:6];  // 64K-depth dual-port 128-bit memory

    always @(posedge clka) begin
        if (ena) begin
            if (wea)
                mem[addra] <= dina;
            douta <= mem[addra];
        end
    end

    always @(posedge clkb) begin
        if (enb) begin
            // $display("web %d", web);
            if (web) begin
                mem[addrb] <= dinb;
                // $display("addrb %d, dinb %d, mem[addrb] %d", addrb, dinb, mem[addrb]);
            end
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
    reg [base_mult-1:0] x;
    reg [base_mult-1:0] y;

    always @(posedge clk) begin
        x <= (a_in == 0)? x1 : x2;
        y <= (b_in == 0)? y1 : y2;
    end
    always @(*) begin
        out = x * y;
    end
endmodule

module generic_multiplier #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 65536)(
    input clk,
    input [$clog2(interface_bits*bram_depth)+1:0] size,
//    output reg done
    output reg [interface_bits-1:0] out,
    output reg [$clog2(bram_depth):0] carry
    );
    
    wire signed [$clog2(interface_bits*bram_depth)+1:0] num_blocks;
    assign num_blocks = size / interface_bits;

    reg [bram_depth-1:0] addra[0:1];
    reg [interface_bits-1:0] dina[0:1];
    reg [interface_bits-1:0] douta[0:1];
    
    reg [bram_depth-1:0] addrb[0:1];
    reg [interface_bits-1:0] dinb[0:1];
    reg [interface_bits-1:0] doutb[0:1];
    reg ena2 = 1'b1;
    reg ena1 = 1'b1;

    reg [$clog2(interface_bits*bram_depth)+1:0] p_a_idx = 0;
    reg [$clog2(interface_bits*bram_depth)+1:0] p_b_idx = 0;
    reg a_in;
    reg b_in;
    reg [31:0] shift_pipe1, shift_pipe2;
    reg [2*base_mult:0] mult_pipe, mult_result;

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

    // reg [2*bram_depth-2:0] carry = 0;

    reg ena = 1'b1;
    reg wea = 1'b0;
    wire [2*bram_depth-2:0] addrouta;
    wire [2*bram_depth-2:0] addroutb;

    reg [2*bram_depth-2:0] addrouta1;
    reg [2*bram_depth-2:0] addroutb1;
    reg [2*bram_depth-2:0] addrouta2;
    reg [2*bram_depth-2:0] addroutb2;
    
    reg [2*base_mult + $clog2(bram_depth):0] dinouta;
    reg [2*base_mult + $clog2(bram_depth):0] dinoutb;
    reg [2*base_mult + $clog2(bram_depth):0] doutouta;
    reg [2*base_mult + $clog2(bram_depth):0] doutoutb;
    
    reg [2*base_mult + $clog2(bram_depth):0] a;
    reg [2*base_mult + $clog2(bram_depth):0] b;
    reg [2*base_mult + $clog2(bram_depth)+1:0] total_sum = 0;
    
    reg enb = 1'b1;
    reg web = 1'b1;

    reg signed [$clog2(interface_bits*bram_depth)+1:0] count = 0;
    reg signed [$clog2(interface_bits*bram_depth)+1:0] a_idx = 0;
    reg signed [$clog2(interface_bits*bram_depth)+1:0] b_idx = 0;
    
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
        // $display("%b", size);
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
        // $display("count %b", count);
    end

    always @(posedge clk) begin
        if(count < 2) begin
            addrouta1 <= 0;
        end
        else if (count >= 2) begin
            if ((p_a_idx <= num_blocks-1) && (p_b_idx <= num_blocks-1)) begin
                a_in = (p_a_idx % 2 == 0)? 1'b0:1'b1;
                b_in = (p_b_idx % 2 == 0)? 1'b0:1'b1;
                // $display("douta[0] %d, doutb[0] %d douta[1] %d doutb[1] %d a_in %d b_in %d", douta[0], doutb[0], douta[1], doutb[1], a_in, b_in);
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

    always @(posedge clk) begin
        shift_pipe2 <= shift_pipe1;
        mult_pipe <= mult_result;
    end

    always @(posedge clk) begin
        shift_pipe3 <= shift_pipe2;
    end

    always @(posedge clk) begin
        if (count >= 5 && count - 5 < num_blocks*num_blocks)begin
            // $display("mult_pipe2 %d, doutouta %d, shift_pipe3 %d", mult_pipe2, doutouta, shift_pipe3);
            addroutb1 <= shift_pipe3;
            dinoutb <= doutouta + {1'b0, mult_pipe};
            // $display("dinoutb %d", dinoutb);
        end
        else if (count - 5 >= num_blocks*num_blocks) begin
            // $display("%b, %b", count-4, num_blocks*num_blocks);
            accumulation_done <= 1'b1;
        end
    end

    reg signed [$clog2(interface_bits*bram_depth)+1:0] idx_a_port = 0;
    reg signed [$clog2(interface_bits*bram_depth)+1:0] idx_b_port = 0;

    always @(posedge clk) begin
        // $display("numblocks %b, idx_a_port %b", num_blocks*num_blocks, idx_a_port);
        if (accumulation_done == 1'b0)begin
            addrouta2 <= 0;
            addroutb2 <= 0;
        end
        else if(accumulation_done == 1'b1 && idx_a_port <= 2*num_blocks-2) begin
            addrouta2 <= idx_a_port;
            if (idx_a_port != 0 && idx_b_port <= 2*num_blocks-2) begin
                addroutb2 <= idx_b_port + 1;
                idx_b_port <= idx_b_port + 1;
            end
            idx_a_port <= idx_a_port + 1;
        end
        else if (accumulation_done == 1'b1 && idx_a_port <= 2*num_blocks && idx_a_port > 2*num_blocks-2) begin
            idx_a_port <= idx_a_port + 1;
            idx_b_port <= idx_b_port + 1;
        end
    end

    always @(posedge clk) begin
        // $display("idx_a_port %b, %b", idx_a_port, num_blocks);
        if(idx_a_port >= 2 && idx_a_port <= 2*num_blocks+1) begin
            a = doutouta;
            // $display("idx_a_port %b, %b", idx_a_port, 2*num_blocks+1);
            if (idx_a_port == 2) begin
                // $display("going 1");
                out <= a[base_mult-1:0];
            end
            else if (idx_a_port == 2*num_blocks+1) begin
                // $display("idx_a_port %b, %b", idx_a_port, 2*num_blocks+1);
                // $display("going 2");
                out <= total_sum[2*base_mult-1:base_mult];
                carry <= total_sum[2*base_mult + $clog2(bram_depth):2*base_mult];
            end
            else if((idx_a_port != 2) && (idx_b_port == 3)) begin
                // $display("going 3");
                b = doutoutb;
                // $display("%d", b);
                total_sum = b + {1'b0, a[2*base_mult + $clog2(bram_depth):base_mult]};
                out <= total_sum[base_mult-1:0];
            end
            else if ((idx_a_port != 2) && (idx_b_port > 3) && (idx_b_port <= 2*num_blocks)) begin
                // $display("going 4");
                b = doutoutb;
                total_sum = b + {1'b0, total_sum[2*base_mult + $clog2(bram_depth):base_mult]};
                out <= total_sum[base_mult-1:0];
            end
        end
    end

endmodule

// Trial 1
// opt_design
// place_design -directive ExtraNetDelay_low
// phys_opt_design -directive AggressiveExplore
// route_design -directive AggressiveExplore
// report_timing_summary
// 5.622 slack
// 714, 296, 16, 40, 6

// Trial 2
// normal implementation -> 5.297
// 717, 293, 16, 40, 6

// Trial 3
// opt_design -directive Explore
// place_design -directive ExtraPostPlacementOpt
// phys_opt_design -directive AggressiveExplore
// route_design -directive Explore
// report_timing_summary
// 5.622

// Trial 4
// opt_design -directive ExploreWithRemap
// place_design -directive Quick
// phys_opt_design -directive AlternateFlowWithRetiming
// route_design -directive AggressiveExplore
// report_timing_summary
// 5.622

// Trial 5
// opt_design -directive AreaOptimized_high
// place_design -directive ExtraNetDelay_high
// phys_opt_design -directive AggressiveExplore
// route_design -directive AggressiveExplore

// Trial 6
// opt_design -directive PowerOpt
// place_design -directive Explore
// phys_opt_design -directive Explore
// route_design -directive AggressiveExplore

// Trial 7
// opt_design -directive ExploreWithRemap
// place_design -directive ExtraPostPlacementOpt
// phys_opt_design -directive AggressiveExplore
// phys_opt_design -directive Explore
// route_design -directive AggressiveExplore

// Trial 8
// set_property CLOCK_REGION {X0Y0:X1Y1} [get_cells <top-level-inst>]
// opt_design -directive Explore
// place_design -directive EarlyBlockPlacement
// phys_opt_design -directive AggressiveExplore
// route_design -directive Explore
