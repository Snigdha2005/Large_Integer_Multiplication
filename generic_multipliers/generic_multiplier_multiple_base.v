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
    input [base_mult-1:0] x,
    input [base_mult-1:0] y,
    output reg [2*base_mult:0] out
);
    always @(*) begin
        out = x * y;
    end
endmodule

module generic_multiplier #(parameter base_mult = 32, parameter bram_depth = 65536)(
    input clk,
    input int size,
//    output reg done
    output reg [base_mult-1:0] out
    );
    
    int num_blocks;

    assign num_blocks = size / base_mult;

    reg [15:0] addra[0:1];
    reg [base_mult-1:0] dina[0:1];
    reg [base_mult-1:0] douta[0:1];
    
    reg [15:0] addrb[0:1];
    reg [base_mult-1:0] dinb[0:1];
    reg [base_mult-1:0] doutb[0:1];
    reg ena = 1'b1;
    reg ena1 = 1'b1;

    reg [base_mult-1:0] x[0:bram_depth-1], y[0:bram_depth-1];
    wire [base_mult*2:0] partial_out[0:bram_depth-1];
    reg [31:0] shift[0:bram_depth-1];
    reg [31:0] shift1[0:bram_depth-1];
    reg [base_mult*2*bram_depth-1:0] final_out = 0;
    reg [base_mult*2:0] partial_out_buffer[0:bram_depth-1];
    
    int prev_size;
    genvar p;
    generate 
        for(p = 0; p < bram_depth; p =  p + 1) begin : MULT_UNITS
            generic_base_multiplier #(base_mult) dut(.x(x[p]), .y(y[p]), .out(partial_out[p]));
        end
    endgenerate

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

    always @(posedge clk) begin
        prev_size <= size;
    end

    always @(posedge clk) begin
        if(prev_size == size || count == 0) begin
        if (count % 2 == 1 && count < num_blocks) begin
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
        else if (count % 2 == 0 && count <= num_blocks) begin
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
        end
        count <= count + 1;
        end
        else begin
            count <= 0;
            addra[0] <= 0;
            addra[0] <= 0;
            addrb[1] <= 0;
            addrb[1] <= 0;
        end
    end

    int idx_a = 0;
    int idx_b = 0;

    reg [base_mult-1:0] a[0:bram_depth-1];
    reg [base_mult-1:0] b[0:bram_depth-1];
    
    always @(posedge clk) begin
        if(prev_size == size) begin
        if(num_blocks > 1) begin
            if(count % 2 == 0 && count < (num_blocks + 4) && count >= 3)begin
                a[idx_a] <= douta[0];
                b[idx_b] <= doutb[0];
                idx_a <= idx_a + 1;
                idx_b <= idx_b + 1;
            end
            else if (count % 2 == 1 && count < (num_blocks + 4) && count >= 4) begin
                a[idx_a] <= douta[1];
                b[idx_b] <= doutb[1];
                idx_a <= idx_a + 1;
                idx_b <= idx_b + 1;
            end
        end
        else if (num_blocks == 1) begin
            a[idx_a] <= douta[0];
            b[idx_b] <= doutb[0];
        end
        end
        else begin
            idx_a <= 0;
            idx_b <= 0;
        end
    end    

    int idx = 0;
    int a_queue[0:(bram_depth*bram_depth/4 - 1)];
    int b_queue[0:(bram_depth*bram_depth/4 - 1)];
    
    int queue_start = 0;
    int queue_ptr = 0;

    always @(posedge clk) begin
        if(prev_size == size) begin
        if (count >= 5 && (count-5) <= num_blocks) begin
            idx <= 0;
            for(int j = 0; j < bram_depth; j = j + 1) begin
                if (j < count-5) begin
                    // $display("j %d, count-6 %d", j, count-6);
                    if (idx < bram_depth)begin
                        x[idx] <= a[j];
                        y[idx] <= b[count-6];
                        shift[idx] <= base_mult * (j + count - 6);
                        // $display("x[idx] %d y[idx] %d", a[j], b[count-6]);
                        // $display("x j %d, y count-6 %d", j, count-6);
                        if (idx + 1 < bram_depth && (j != count-6))begin
                            x[idx+1] <= a[count-6];
                            y[idx+1] <= b[j];
                            shift[idx+1] <= base_mult * (j + count - 6);
                            idx <= idx + 1;
                            // $display("x[idx+!] %d y[idx+1] %d", a[count-6], b[j]);
                            // $display("y j %d, x count-6 %d", j, count-6);
                        end
                        else if (idx + 1 >= bram_depth) begin
                            a_queue[queue_start] <= count-6;
                            b_queue[queue_start] <= j;
                            queue_start <= queue_start + 1;
                            // $display("queue y j %d, x count-6 %d", j, count-6);
                        end
                        idx <= idx + 1;
                    end
                    else if (idx >= bram_depth) begin
                        a_queue[queue_start] <= j;
                        b_queue[queue_start] <= count-6;
                        // $display("queue x j %d, y count-6 %d", j, count-6);
                        if (j != count-6) begin
                            a_queue[queue_start] <= count-6;
                            b_queue[queue_start] <= j;
                            queue_start <= queue_start + 1;
                            // $display("queue idx y j %d, x count-6 %d", j, count-6);
                        end
                        queue_start <= queue_start + 1;
                    end
                end
                else begin
                    x[j] <= 32'b0;
                    y[j] <= 32'b0;
                    shift[j] <= 32'b0;
                end
            end
            // for(int j = count-5; j < bram_depth; j = j + 1) begin
            //     x[j] <= 32'b0;
            //     y[j] <= 32'b0;
            //     shift[j] <= 32'b0;
            // end
        end
        else if((count-5) >= num_blocks) begin
            for(int i = 0; i < bram_depth; i = i + 1)begin
                if(queue_ptr < queue_start) begin
                    x[i] <= a[a_queue[queue_ptr]];
                    y[i] <= b[b_queue[queue_ptr]];
                    shift[i] <= base_mult * (a_queue[queue_ptr] + b_queue[queue_ptr]);
                    queue_ptr <= queue_ptr + 1;
                end
                else begin
                    x[i] <= 32'b0;
                    y[i] <= 32'b0;
                    shift[i] <= 32'b0;
                end 
            end
        end
        end
    end

    always @(posedge clk) begin
        if(prev_size == size) begin
        if (count >= 6) begin
            for(int i = 0; i < bram_depth; i = i + 1) begin
                partial_out_buffer[i] <= partial_out[i];
                shift1[i] <= shift[i];
                // $display("partial_out[i] %d", partial_out[i]);
                // final_out <= final_out + partial_out[i] << shift[i];
            end
        end
        end
    end
    always @(posedge clk) begin
        if(prev_size == size) begin
        if (count >= 7 && count <= num_blocks*num_blocks) begin
            for(int i = 0; i < bram_depth; i = i + 1) begin
                // partial_out_buffer <= partial_out[i];
                // $display("partial_out[i] %d", partial_out[i]);
                final_out <= final_out + partial_out_buffer[i] << shift1[i];
                // $display("partial_out[i] %h", partial_out_buffer[i]);
            end
        end
        end
    end

    // always @(posedge clk) begin
    //     if((count-5) >= num_blocks) begin
    //         for(int i = 0; i < bram_depth; i = i + 1)begin
    //             if(queue_ptr < queue_start) begin
    //                 x[i] <= a[a_queue[queue_ptr]];
    //                 y[i] <= b[b_queue[queue_ptr]];
    //                 shift[i] <= base_mult * (a_queue[queue_ptr] + b_queue[queue_ptr]);
    //                 queue_ptr <= queue_ptr + 1;
    //             end
    //             else begin
    //                 x[i] <= 32'b0;
    //                 y[i] <= 32'b0;
    //                 shift[i] <= 32'b0;
    //             end 
    //         end
    //     end
    // end
endmodule
