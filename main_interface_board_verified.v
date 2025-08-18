module out #(parameter add_no = 7, parameter partial = 66)(
    input wire clka,
    input wire ena,
    input wire wea,
    input wire [add_no-1:0] addra,
    input wire [partial-1:0] dina,
    output reg [partial-1:0] douta,

    input wire clkb,
    input wire enb,
    input wire web,
    input wire [add_no-1:0] addrb,
    input wire [partial-1:0] dinb,
    output reg [partial-1:0] doutb
);

    reg [partial-1:0] mem [0:add_no-1];  // 64K-depth dual-port 128-bit memory

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
    input [base_mult-1:0] x,
    input [base_mult-1:0] y,
    output [2*base_mult:0] out
);
    assign out = x*y;
endmodule

module generic_multiplier #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 2048)(
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
//    wire [interface_bits-1:0] out;
//    wire [interface_bits-1:0] x;
//    wire [interface_bits-1:0] y;
    
    reg [interface_bits-1:0] in1;
    reg [interface_bits-1:0] in2;
    reg [$clog2(interface_bits*bram_depth)+1:0] prev_size;
    reg [interface_bits-1:0] outf;
//    reg [$clog2(bram_depth):0] carry1;
    reg [$clog2(interface_bits*bram_depth)+1:0] p_a_idx = 0;
    reg [$clog2(interface_bits*bram_depth)+1:0] p_b_idx = 0;
    reg [31:0] shift_pipe1, shift_pipe2;
    reg [2*base_mult:0] mult_pipe; 
    wire [2*base_mult:0] mult_result;
    
    generic_base_multiplier #(base_mult) dut(.clk(clk), .x(in1), .y(in2), .out(mult_result));
    
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
    wire [2*base_mult + $clog2(bram_depth):0] doutouta;
    wire [2*base_mult + $clog2(bram_depth):0] doutoutb;
    
    reg [2*base_mult + $clog2(bram_depth):0] a;
    reg [2*base_mult + $clog2(bram_depth):0] b;
    reg [2*base_mult + $clog2(bram_depth)+1:0] total_sum = 0;
    
    reg enb = 1'b1;
    reg web = 1'b1;

    reg signed [$clog2(interface_bits*bram_depth)+1:0] count = 0;
    
    reg accumulation_done = 1'b0;

    assign addrouta = (accumulation_done == 1'b1)? addrouta2:addrouta1;
    assign addroutb = (accumulation_done == 1'b1)? addroutb2:addroutb1;
    localparam add_no = 2*bram_depth-1;
    localparam partial = 2*base_mult+$clog2(bram_depth)+1;
    out #(add_no, partial) final_out (
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
        if ((prev_size == size || count == 0) && (reset == 1'b0)) begin
            count <= count + 1;
        end
        else begin
            count <= 0;
        end
        // $display("count %b", count);
    end

    always @(posedge clk) begin
        if((prev_size == size || count == 0) && (reset == 1'b0)) begin
            if (count >= 0) begin
                if ((p_a_idx <= num_blocks-1) && (p_b_idx <= num_blocks-1)) begin
                    in1 = x;
                    in2 = y;
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
            in1 = 0;
            in2 = 0;
        end
    end

    always @(posedge clk) begin
        if ((prev_size == size || count == 0) && (reset == 1'b0)) begin
            shift_pipe2 <= shift_pipe1;
            mult_pipe <= mult_result;
        end
        else begin
            shift_pipe2 <= 0;
            mult_pipe <= 0;
        end
    end
    reg [2*bram_depth-2:0] map;
    reg [2*base_mult + $clog2(bram_depth):0] mult_rr, mid;
    always @(posedge clk) begin
        if(prev_size == size && (reset == 1'b0)) begin
            if (count >= 2 && count - 2 < num_blocks*num_blocks)begin
                mult_rr = {1'b0, mult_pipe};
                if(num_blocks == 2 && shift_pipe2 == 1)begin
                    mid <= mult_rr + mid;
                end
                // $display("mult_pipe2 %d, doutouta %d, shift_pipe3 %d", mult_pipe2, doutouta, shift_pipe3);
                else begin
                    web <= 1'b1;
                    addroutb1 <= shift_pipe2;
                    dinoutb <= (map[shift_pipe2] == 1'b1) ? (doutouta + mult_rr): mult_rr;
                    map[addroutb1] = 1'b1;
                end
                accumulation_done <= 1'b0;
                // $display("dinoutb %d", dinoutb);
            end
            else if (count - 2 >= num_blocks*num_blocks+1) begin
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

    reg signed [$clog2(interface_bits*bram_depth)+1:0] idx_a_port = 0;
    reg signed [$clog2(interface_bits*bram_depth)+1:0] idx_b_port = 0;

    always @(posedge clk) begin
        if(prev_size == size && (reset == 1'b0))begin
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
        if(prev_size == size && (reset == 1'b0))begin
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
