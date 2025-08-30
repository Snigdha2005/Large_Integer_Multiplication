module generic_base_multiplier #(parameter base_mult = 10)(
    input clk,
    input [base_mult-1:0] x1,
    input [base_mult-1:0] y1,
    input [base_mult-1:0] x2,
    input [base_mult-1:0] y2,
    input a_in,
    input b_in,
    output [2*base_mult:0] out
);
    reg [base_mult-1:0] x11;
    reg [base_mult-1:0] x21;
    reg [base_mult-1:0] y11;
    reg [base_mult-1:0] y21;
    reg a_in_x;
    reg b_in_x;
    always @(posedge clk) begin
        x11 <= x1;
        x21 <= x2;
        y11 <= y1;
        y21 <= y2;
        a_in_x <= a_in;
        b_in_x <= b_in;
    end
    assign out = (a_in_x == 0)? ((b_in_x == 0) ? x11 * y11 : x11 * y21) : ((b_in_x == 0) ? x21 * y11 : x21 * y21);
    
//    assign out = (a_in == 0)? ((b_in == 0) ? x1 * y1 : x1 * y2) : ((b_in == 0) ? x2 * y1 : x2 * y2);
endmodule

//module generic_base_multiplier #(parameter base_mult = 10)(
//    input clk,
//    input [base_mult-1:0] x1,
//    input [base_mult-1:0] y1,
//    input [base_mult-1:0] x2,
//    input [base_mult-1:0] y2,
//    input a_in,
//    input b_in,
//    output [2*base_mult:0] out
//);
//    assign out = (a_in == 0)? ((b_in == 0) ? x1 * y1 : x1 * y2) : ((b_in == 0) ? x2 * y1 : x2 * y2);
//endmodule

module generic_multiplier #(parameter base_mult = 128, parameter interface_bits = 128, parameter bram_depth = 512)(
    input clk,
    input [$clog2(interface_bits*bram_depth)+1:0] size,
    input [interface_bits-1:0] x,
    input [interface_bits-1:0] y,
//    output reg done
   output [interface_bits-1:0] out,
    input reset,
    output reg [$clog2(bram_depth):0] carry
    );
    
    wire signed [$clog2(interface_bits*bram_depth)+1:0] num_blocks;
    assign num_blocks = size / interface_bits;
    
    reg [$clog2(interface_bits*bram_depth)+1:0] prev_size;
    reg [interface_bits-1:0] outf;
    wire [bram_depth-1:0] addra0, addra1;
    reg [bram_depth-1:0] addra00, addra01;
    reg [bram_depth-1:0] addra10, addra11;
    reg [interface_bits-1:0] dina0, dina1;
    wire [interface_bits-1:0] douta0, douta1;
//    reg [$clog2(bram_depth):0] carry1;
    wire [bram_depth-1:0] addrb0, addrb1;
    reg [bram_depth-1:0] addrb00, addrb01;
    reg [bram_depth-1:0] addrb10, addrb11;
    reg [interface_bits-1:0] dinb0, dinb1;
    wire [interface_bits-1:0] doutb0, doutb1;
    reg ena2 = 1'b1;
    reg ena1 = 1'b1;
    reg wein = 1'b1;
    reg [$clog2(interface_bits*bram_depth)+1:0] p_a_idx = 0;
    reg [$clog2(interface_bits*bram_depth)+1:0] p_b_idx = 0;
    reg a_in;
    reg b_in;
    reg [31:0] shift_pipe1, shift_pipe2, shift_pipe3;
//    (* dont_touch = "yes" *)reg [31:0] shift_pipe3;
    reg [2*base_mult:0] mult_pipe; 
    (* use_dsp = "yes" *) wire [2*base_mult:0] mult_result;
    
    generic_base_multiplier #(base_mult) dut(.clk(clk), .x1(douta0), .y1(doutb0), .x2(douta1), .y2(doutb1), .a_in(a_in), .b_in(b_in), .out(mult_result));
    a a1 (
      .clka(clk),    // input wire clka
      .ena(ena2), 
      .wea(wein),      // input wire [0 : 0] wea
      .addra(addra0),  // input wire [15 : 0] addra
      .dina(dina0),    // input wire [31 : 0] dina
      .douta(douta0)  // output wire [31 : 0] douta
    );
    a a2 (
      .clka(clk),    // input wire clka
      .ena(ena1), 
      .wea(wein),      // input wire [0 : 0] wea
      .addra(addra1),  // input wire [15 : 0] addra
      .dina(dina1),    // input wire [31 : 0] dina
      .douta(douta1)  // output wire [31 : 0] douta
    );
    a b1 (
      .clka(clk),    // input wire clka
      .ena(ena2), 
      .wea(wein),      // input wire [0 : 0] wea
      .addra(addrb0),  // input wire [15 : 0] addra
      .dina(dinb0),    // input wire [31 : 0] dina
      .douta(doutb0)  // output wire [31 : 0] douta
    );
    a b2 (
      .clka(clk),    // input wire clka
      .ena(ena1), 
      .wea(wein),      // input wire [0 : 0] wea
      .addra(addrb1),  // input wire [15 : 0] addra
      .dina(dinb1),    // input wire [31 : 0] dina
      .douta(doutb1)  // output wire [31 : 0] douta
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
    reg [2*base_mult + $clog2(bram_depth):0] dinoutb_dup;
    wire [2*base_mult + $clog2(bram_depth):0] doutouta;
    wire [2*base_mult + $clog2(bram_depth):0] doutoutb;
    
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
    assign addra0 = (wein == 1'b1)?addra00:addra01;
    assign addra1 = (wein == 1'b1)?addra10:addra11;
    assign addrb0 = (wein == 1'b1)?addrb00:addrb01;
    assign addrb1 = (wein == 1'b1)?addrb10:addrb11;
    
    outp final_out (
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
    
    reg [$clog2(interface_bits*bram_depth)+1:0] c = 0;
    
    always @(posedge clk) begin
        if (reset == 1'b0 && wein == 1'b1) begin
            if(c == 0 && num_blocks == 1)begin
                addra00 <= c;
                dina0 <= x;
                addra10 <= c;
                dina1 <= 0;
                
                addrb00 <= c;
                dinb0 <= y;
                addrb10 <= c;
                dinb1 <= 0;
                
                c <= c + 1;
                wein <= 1'b1;
            end
            if(c <= num_blocks-1 && num_blocks != 1) begin
                if(c % 2 == 0)begin
                    addra00 <= c / 2;
                    dina0 <= x;
                    addrb00 <= c / 2;
                    dinb0 <= y;
                end
                else begin
                    addra10 <= c / 2;
                    dina1 <= x;
                    addrb10 <= c / 2;
                    dinb1 <= y;
                end
                c <= c + 1;
                wein <= 1'b1;
            end
            else begin
                wein <= 1'b0;
            end
        end
        else if(reset == 1'b1) begin
            c <= 0;
            wein <= 1'b1;
            addra00 <= 0;
            addra10 <= 0;
            addrb00 <= 0;
            addrb10 <= 0;
        end
     end
     always@(posedge clk)begin
        if ((prev_size == size || count == 0) && (wein == 1'b0 && reset == 1'b0)) begin
        // $display("%b", size);
            if(a_idx == 0) begin
                addra01 <= 32'b0;
                a_idx <= a_idx + 1;
            end
            else if (a_idx == 1) begin
                addra11 <= 32'b0;
                a_idx <= a_idx + 1;
            end
            else if ((a_idx < num_blocks-1) && (a_idx > 1)) begin
                if (a_idx % 2 == 0) begin
                    addra01 <= addra01 + 1;
                end
                else if (a_idx % 2 == 1) begin
                    addra11 <= addra11 + 1;
                end
                a_idx <= a_idx + 1;
            end
            else if ((a_idx == num_blocks-1) && (a_idx > 1)) begin
                addra11 <= addra11 + 1;
                a_idx <= 0;
            end
    
            if (b_idx == 0) begin
                addrb01 <= 32'b0;
                b_idx <= b_idx + 1;
            end 
            else if (b_idx == 1 && ((a_idx == num_blocks-2) || (num_blocks-2 <= 0))) begin
                addrb11 <= 32'b0;
                b_idx <= b_idx + 1;
            end
            else if ((b_idx < num_blocks) && (a_idx == num_blocks-2) && (b_idx > 1)) begin
                if (b_idx % 2 == 0) begin
                    addrb01 <= addrb01 + 1;
                end
                else if (b_idx % 2 == 1) begin
                    addrb11 <= addrb11 + 1;
                end
                b_idx <= b_idx + 1;
            end
            count <= count + 1;
        end
        else begin
            count <= 0;
            a_idx <= 0;
            b_idx <= 0;
            addra01 <= 0;
            addra11 <= 0;
            addrb01 <= 0;
            addrb11 <= 0;
        end
        // $display("count %b", count);
    end

    always @(posedge clk) begin
        if((prev_size == size || count == 0) && (wein == 1'b0)) begin
            if(count < 2) begin
                addrouta1 <= 0;
                p_a_idx <= 0;
                p_b_idx <= 0;
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
        else begin
            p_a_idx <= 0;
            p_b_idx <= 0;
            addrouta1 <= 7;
            a_in = 0;
            b_in = 0;
        end
    end

    always @(posedge clk) begin
        if ((prev_size == size || count == 0) && (wein == 1'b0)) begin
//            shift_pipe2 <= shift_pipe1;
            shift_pipe3 <= shift_pipe1;
//            mult_pipe <= mult_result;
        end
        else begin
//            shift_pipe2 <= 0;
            shift_pipe3 <= 0;
//            mult_pipe <= 0;
        end
    end
    always @(posedge clk)begin
        if ((prev_size == size || count == 0) && (wein == 1'b0) && count >= 4 && count-4<num_blocks*num_blocks) begin
            shift_pipe2 <= shift_pipe3;
//            shift_pipe3 <= shift_pipe1;
            mult_pipe <= mult_result;
            dinoutb_dup <= doutouta;
        end
        else begin
            shift_pipe2 <= 0;
//            shift_pipe3 <= 0;
            dinoutb_dup <= 0;
            mult_pipe <= 0;
        end
    end
    reg [2*bram_depth-2:0] map;
    reg [2*base_mult + $clog2(bram_depth):0] mult_rr, mid;
    always @(posedge clk) begin
        if(prev_size == size && (wein == 1'b0)) begin
            if (count >= 5 && count - 5 < num_blocks*num_blocks)begin
                mult_rr = {1'b0, mult_pipe};
                if(num_blocks == 2 && shift_pipe2 == 1)begin
                    mid <= mult_rr + mid;
                end
                // $display("mult_pipe2 %d, doutouta %d, shift_pipe3 %d", mult_pipe2, doutouta, shift_pipe3);
                else begin
                    web <= 1'b1;
                    addroutb1 <= shift_pipe2;
                    dinoutb <= (map[shift_pipe2] == 1'b1) ? (dinoutb_dup + mult_rr): mult_rr;
                    map[addroutb1] = 1'b1;
                end
                accumulation_done <= 1'b0;
                // $display("dinoutb %d", dinoutb);
            end
            else if (count - 5 >= num_blocks*num_blocks+1) begin
                // $display("%b, %b", count-4, num_blocks*num_blocks);
                accumulation_done <= 1'b1;
                web <= 1'b0;
            end
        end
        else begin
            addroutb1 <= 1;
            dinoutb <= 0;
            web <= 1'b1;
            map = 0;
            mult_rr = 0;
            mid <= 0;
            accumulation_done <= 0;
        end
    end

//    always @(posedge clk)begin
//        if(accumulation_done == 1'b1 && (addrouta2 <= 2*bram_depth-1)) begin
//            addrouta2 <= addrouta2 + 1;
//            addroutb2 <= addroutb2 + 1;
//        end
//        else begin
//            addrouta2 <= 0;
//            addroutb2 <= 1;
//        end
//    end
    reg signed [$clog2(interface_bits*bram_depth)+1:0] idx_a_port = 0;
    reg signed [$clog2(interface_bits*bram_depth)+1:0] idx_b_port = 0;

    always @(posedge clk) begin
        if(prev_size == size && (wein == 1'b0))begin
        // $display("numblocks %b, idx_a_port %b", num_blocks*num_blocks, idx_a_port);
            if (accumulation_done == 1'b0)begin
                addrouta2 <= 0;
                addroutb2 <= 0;
                idx_a_port <= 0;
                idx_b_port <= 0;
//                map[shift_pipe2] <= 1'b1;
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
        else begin
            addrouta2 <= 0;
            addroutb2 <= 0;
            idx_a_port <= 0;
            idx_b_port <= 0;
//            map <= 0;
        end
    end

    always @(posedge clk) begin
        if(prev_size == size && (wein == 1'b0))begin
            // $display("idx_a_port %b, %b", idx_a_port, num_blocks);
            if(idx_a_port >= 1 && idx_a_port <= 2*num_blocks+1) begin
                a = doutouta;
                // $display("idx_a_port %b, %b", idx_a_port, 2*num_blocks+1);
                if (idx_a_port == 1) begin
                    // $display("going 1");
                    outf <= a[base_mult-1:0];
                    total_sum = 0;
                end
                else if (idx_a_port == 2*num_blocks+1) begin
                    // $display("idx_a_port %b, %b", idx_a_port, 2*num_blocks+1);
                    // $display("going 2");
                    outf <= total_sum[2*base_mult-1:base_mult];
                    carry <= total_sum[2*base_mult + $clog2(bram_depth):2*base_mult];
                end
                else if((idx_a_port != 1) && (idx_b_port == 2)) begin
                    // $display("going 3");
                    b = doutoutb;
                    // $display("%d", b);
                    total_sum = (num_blocks == 2)? (mid + {1'b0, a[2*base_mult + $clog2(bram_depth):base_mult]}): (b + {1'b0, a[2*base_mult + $clog2(bram_depth):base_mult]});
                    outf <= total_sum[base_mult-1:0];
                end
                else if ((idx_a_port != 1) && (idx_b_port > 2) && (idx_b_port <= 2*num_blocks)) begin
                    // $display("going 4");
                    b = doutoutb;
                    total_sum = b + {1'b0, total_sum[2*base_mult + $clog2(bram_depth):base_mult]};
                    outf <= total_sum[base_mult-1:0];
                end
            end
        end
        else begin
            outf <= 0;
            carry <= 0;
            a = 0;
            b = 0;
            total_sum = 0;
        end
    end

assign out = outf;
endmodule

// module top #(parameter base_mult = 32, interface_bits = 32, bram_depth = 4)(
//     input clk,
//     input reset,
//     output [$clog2(bram_depth):0] carry,
//     input [$clog2(interface_bits*bram_depth)+1:0] size
// );
//     reg [2*interface_bits-1:0] x;
//     reg [2*interface_bits-1:0] y;
    
//     generic_multiplier #(base_mult, interface_bits, bram_depth) multi(clk, size, x, y, reset, carry);
//     integer p = 0;
    
//     always @(posedge clk) begin
//         if (reset)
//             p <= 0;
//         else if (p < size/(2*base_mult))
//             p <= p + 1;
//     end
//     always @* begin
//         if (reset == 1'b1) begin
//             x = 0;
//             y = 0;
//         end
//         else if (p == 0 && (size/2*base_mult < 1))begin
//             x = 64'b00000000000000000000000000000000_00000000000000000000000001000001;
//             y = 64'b00000000000000000000000000000000_00000000000000000000000001000001;
//         end
//         else if (p < size/(2*base_mult)) begin
//             if (p % 2 == 0) begin
//                 x = 64'b00000000000000000000000000000010_00000000000000000000000001000001;
//                 y = 64'b00000000000000000000000000000010_00000000000000000000000001000001;
//             end
//             else begin
//                 x = 64'b00000000000000000000000000000011_00000000000000000000000001000010;
//                 y = 64'b00000000000000000000000000000011_00000000000000000000000001000010;
//             end
//         end
//         else begin
//             x = 0;
//             y = 0;
//         end
//     end
    
//     ila_0 ila_analyse(
//         .clk(clk), // input wire clk
//         .probe0(size), // input wire [8:0]  probe0  
//         .probe1(multi.count), // input wire [8:0]  probe1 
//         .probe2(multi.p_a_idx), // input wire [8:0]  probe2 
//         .probe3(multi.p_b_idx), // input wire [8:0]  probe3 
//         .probe4(multi.idx_a_port), // input wire [8:0]  probe4 
//         .probe5(multi.idx_b_port), // input wire [8:0]  probe5 
//         .probe6(multi.outf), // input wire [31:0]  probe6
//         .probe7(multi.reset),
//         .probe8(carry),
//         .probe9(multi.mult_pipe),
//         .probe10(multi.shift_pipe2),
//         .probe11(multi.dina0),
//         .probe12(multi.dina1),
//         .probe13(multi.doutb0),
//         .probe14(multi.doutb1),
//         .probe15(multi.addra00),
//         .probe16(multi.addra01),
//         .probe17(multi.addrb00),
//         .probe18(multi.addrb01),
//         .probe19(multi.a_idx),
//         .probe20(multi.b_idx),
//         .probe21(multi.accumulation_done),
//         .probe22(multi.doutouta),
//         .probe23(multi.dinoutb),
//         .probe24(multi.addrouta2),
//         .probe25(multi.addroutb2),
//         .probe26(multi.addrouta1),
//         .probe27(multi.addroutb1),
//         .probe28(multi.map),
//         .probe29(multi.a),
//         .probe30(multi.b),
//         .probe31(multi.total_sum),
//         .probe32(x),
//         .probe33(y),
//         .probe34(p),
//         .probe35(multi.wein),
//         .probe36(multi.douta0),
//         .probe37(multi.douta1),
//         .probe38(multi.c)
//     );
    
// endmodule