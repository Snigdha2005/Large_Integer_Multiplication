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

// module karatsuba_recursive #(
//     parameter base_mult = 32,
//     parameter bram_depth = 4,
//     parameter interface_bits = 32,
//     parameter LEVEL = 0,
//     parameter MAX_LEVELS = 3
// )(
//     input wire clk,
//     input wire start,
//     input wire [bram_depth*interface_bits-1:0] a,
//     input wire [bram_depth*interface_bits-1:0] b,
//     output reg [2*bram_depth*interface_bits-1:0] outf,
//     input integer size
// );
//     // Fixed half sizes based on bram_depth
//     localparam HALF_DEPTH = bram_depth / 2;
//     localparam REM_DEPTH  = bram_depth - HALF_DEPTH;

//     // Extract segments using interface_bits * index math
//     wire [HALF_DEPTH*interface_bits-1:0] a_lo = a[HALF_DEPTH*interface_bits-1:0];
//     wire [REM_DEPTH*interface_bits-1:0]  a_hi = a[bram_depth*interface_bits-1:HALF_DEPTH*interface_bits];

//     wire [HALF_DEPTH*interface_bits-1:0] b_lo = b[HALF_DEPTH*interface_bits-1:0];
//     wire [REM_DEPTH*interface_bits-1:0]  b_hi = b[bram_depth*interface_bits-1:HALF_DEPTH*interface_bits];

//     // Extend and sum partials for middle term
//     wire [(REM_DEPTH+1)*interface_bits-1:0] sum_a = {{interface_bits{1'b0}}, a_lo} + {{interface_bits{1'b0}}, a_hi};
//     wire [(REM_DEPTH+1)*interface_bits-1:0] sum_b = {{interface_bits{1'b0}}, b_lo} + {{interface_bits{1'b0}}, b_hi};

//     // Outputs of recursive or base multipliers
//     wire [2*HALF_DEPTH*interface_bits-1:0] z0;
//     wire [2*REM_DEPTH*interface_bits-1:0]  z2;
//     wire [2*(REM_DEPTH+1)*interface_bits-1:0] z1;

//     reg  [2*(REM_DEPTH+1)*interface_bits-1:0] mid;
//     reg  [2*bram_depth*interface_bits-1:0] result;
    
//     initial begin
//         $display("half_depth = %d, rem_depth = %d, bram_depth = %d, interface_bits = %d", 
//                 bram_depth / 2, bram_depth - (bram_depth / 2), bram_depth, interface_bits);
//     end

//     generate
//         if (LEVEL < MAX_LEVELS) begin : gen_recursive
//             karatsuba_recursive #(
//                 .base_mult(base_mult),
//                 .bram_depth(HALF_DEPTH),
//                 .interface_bits(interface_bits),
//                 .LEVEL(LEVEL + 1)
//             ) rec_z0 (
//                 .clk(clk),
//                 .start(start),
//                 .a(a_lo),
//                 .b(b_lo),
//                 .outf(z0),
//                 .size(HALF_DEPTH*interface_bits)
//             );

//             karatsuba_recursive #(
//                 .base_mult(base_mult),
//                 .bram_depth(REM_DEPTH),
//                 .interface_bits(interface_bits),
//                 .LEVEL(LEVEL + 1)
//             ) rec_z2 (
//                 .clk(clk),
//                 .start(start),
//                 .a(a_hi),
//                 .b(b_hi),
//                 .outf(z2),
//                 .size(REM_DEPTH*interface_bits)
//             );

//             karatsuba_recursive #(
//                 .base_mult(base_mult),
//                 .bram_depth(REM_DEPTH+1),
//                 .interface_bits(interface_bits),
//                 .LEVEL(LEVEL + 1)
//             ) rec_z1 (
//                 .clk(clk),
//                 .start(start),
//                 .a(sum_a),
//                 .b(sum_b),
//                 .outf(z1),
//                 .size((REM_DEPTH+1)*interface_bits)
//             );
//         end else begin : gen_base
//             assign z0 = a_lo * b_lo;
//             assign z2 = a_hi * b_hi;
//             assign z1 = sum_a * sum_b;
//         end
//     endgenerate

//     // Final result assembly
//     always @(posedge clk) begin
//         if (start) begin
//             mid    = z1 - z2 - z0;
//             result = (z2 << (2*HALF_DEPTH*interface_bits)) + (mid << (HALF_DEPTH*interface_bits)) + z0;
//             outf   <= result;
//         end
//     end
// endmodule

// module generic_multiplier_karatsuba #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 4, parameter MAX_LEVELS = 3)(
//     input clk,
//     input int size,
//     output reg [interface_bits-1:0] out
// );
//     int num_clocks;
//     assign num_clocks = size / interface_bits;
//     reg [15:0] addra[0:1];
//     reg [interface_bits-1:0] dina[0:1];
//     reg [interface_bits-1:0] douta[0:1];
    
//     reg [15:0] addrb[0:1];
//     reg [interface_bits-1:0] dinb[0:1];
//     reg [interface_bits-1:0] doutb[0:1];
    
// //    reg [15:0] addrout = 1'b0;
// //    reg [interface_bits-1:0] dinout;
// //    reg [interface_bits-1:0] doutout;
//     reg ena = 1'b1;
//     reg ena1 = 1'b1;
//     a a1 (
//       .clka(clk),    // input wire clka
//       .ena(ena), 
//       .wea(1'b0),      // input wire [0 : 0] wea
//       .addra(addra[0]),  // input wire [15 : 0] addra
//       .dina(dina[0]),    // input wire [31 : 0] dina
//       .douta(douta[0])  // output wire [31 : 0] douta
//     );
//     a a2 (
//       .clka(clk),    // input wire clka
//       .ena(ena1), 
//       .wea(1'b0),      // input wire [0 : 0] wea
//       .addra(addra[1]),  // input wire [15 : 0] addra
//       .dina(dina[1]),    // input wire [31 : 0] dina
//       .douta(douta[1])  // output wire [31 : 0] douta
//     );
//     a b1 (
//       .clka(clk),    // input wire clka
//       .ena(ena), 
//       .wea(1'b0),      // input wire [0 : 0] wea
//       .addra(addrb[0]),  // input wire [15 : 0] addra
//       .dina(dinb[0]),    // input wire [31 : 0] dina
//       .douta(doutb[0])  // output wire [31 : 0] douta
//     );
//     a b2 (
//       .clka(clk),    // input wire clka
//       .ena(ena1), 
//       .wea(1'b0),      // input wire [0 : 0] wea
//       .addra(addrb[1]),  // input wire [15 : 0] addra
//       .dina(dinb[1]),    // input wire [31 : 0] dina
//       .douta(doutb[1])  // output wire [31 : 0] douta
//     );
// //    a total_output (
// //      .clka(clk),    // input wire clka
// //      .wea(1'b1),      // input wire [0 : 0] wea
// //      .addra(addrout),  // input wire [15 : 0] addra
// //      .dina(dinout),    // input wire [64 : 0] dina
// //      .douta(doutout)  // output wire [64 : 0] douta
// //    );

//     int count = 0;
//     reg [bram_depth*interface_bits-1:0] a = 0;
//     reg [bram_depth*interface_bits-1:0] b = 0;
//     reg start = 0;
//     wire [2*bram_depth*interface_bits:0] outf;
//     karatsuba_recursive #(base_mult, bram_depth, interface_bits, 0, MAX_LEVELS) dut(clk, start, a, b, outf, size);

//     always @(posedge clk)begin
//         if(count % 2 == 1 && count < num_clocks && (num_clocks > 1)) begin
//             if (count > 1) begin
//                 addra[0] <= addra[0] + 1;
//                 addrb[0] <= addrb[0] + 1;
//             end
//             else if (count == 1) begin
//                 addra[0] <= 32'b0;
//                 addrb[0] <= 32'b0;
//             end
//         end
//         else if ((count % 2 == 0) && (count <= num_clocks) && (num_clocks > 1))begin
//             if(count > 2)begin
//                 addra[1] <= addra[1] + 1;
//                 addrb[1] <= addrb[1] + 1;
//             end
//             else if (count == 2) begin
//                 addra[1] <= 32'b0;
//                 addrb[1] <= 32'b0;
//             end
//         end
//         else if (count % 2 == 1 && num_clocks <= 1) begin
//             addra[0] <= 32'b0;
//             addrb[0] <= 32'b0;
//         end
//         count <= count + 1;
//     end
    
//     always @(posedge clk) begin
//         if (num_clocks > 1) begin
//             if(count % 2 == 0 && count < (num_clocks + 4) && count >= 3) begin
//                 a <= {a, douta[0]};
//                 b <= {b, doutb[0]};
//             end
//             else if(count % 2 == 1 && count < (num_clocks + 4) && count >= 4) begin
//                 a <= {a, douta[1]};
//                 b <= {b, doutb[1]}; 
//             end
//             else if (count == num_clocks + 4) begin
//                 start <= 1;
//             end
//         end
//         else begin
//             if (count == 4) begin
//                 a <= {1'b0, douta[0]};
//                 b <= {1'b0, doutb[0]};
//             end
//         end
//     end
//     reg [31:0] out_idx = 0;
//     always @(posedge clk) begin
//         if (count >= 13 && out_idx < 2*size) begin
//             out <= outf[out_idx +: interface_bits];
//             out_idx <= out_idx + interface_bits;
//         end
//     end
// endmodule

`timescale 1ns / 1ps
module karatsuba_recursive #(
    parameter base_mult = 32,
    parameter bram_depth = 4,
    parameter interface_bits = 32,
    parameter LEVEL = 0,
    parameter MAX_LEVELS = 3
)(
    input wire clk,
    input wire start,
    input wire [bram_depth*interface_bits-1:0] a,
    input wire [bram_depth*interface_bits-1:0] b,
    output reg [2*bram_depth*interface_bits-1:0] outf,
    input integer size
);
    // Fixed half sizes based on bram_depth
    localparam HALF_DEPTH = interface_bits / 2;
    localparam REM_DEPTH  = interface_bits - HALF_DEPTH;

    // Extract segments using interface_bits * index math
    wire [HALF_DEPTH*bram_depth-1:0] a_lo = a[HALF_DEPTH*bram_depth-1:0];
    wire [REM_DEPTH*bram_depth-1:0]  a_hi = a[bram_depth*interface_bits-1:HALF_DEPTH*bram_depth];

    wire [HALF_DEPTH*bram_depth-1:0] b_lo = b[HALF_DEPTH*bram_depth-1:0];
    wire [REM_DEPTH*bram_depth-1:0]  b_hi = b[bram_depth*interface_bits-1:HALF_DEPTH*bram_depth];

    // Extend and sum partials for middle term
    wire [(REM_DEPTH+1)*bram_depth-1:0] sum_a = {{interface_bits{1'b0}}, a_lo} + {{interface_bits{1'b0}}, a_hi};
    wire [(REM_DEPTH+1)*bram_depth-1:0] sum_b = {{interface_bits{1'b0}}, b_lo} + {{interface_bits{1'b0}}, b_hi};

    // Outputs of recursive or base multipliers
    reg [2*HALF_DEPTH*bram_depth-1:0] z0;
    reg [2*REM_DEPTH*bram_depth-1:0]  z2;
    reg [2*(REM_DEPTH+1)*bram_depth-1:0] z1;

    // reg  [2*(REM_DEPTH+1)*bram_depth-1:0] mid;
    // reg  [2*bram_depth*interface_bits-1:0] result;
    
    initial begin
        $display("half_depth = %d, rem_depth = %d, bram_depth = %d, interface_bits = %d", 
                bram_depth / 2, bram_depth - (bram_depth / 2), bram_depth, interface_bits);
    end

    generate
        if (LEVEL < MAX_LEVELS) begin : gen_recursive
            karatsuba_recursive #(
                .base_mult(base_mult),
                .bram_depth(bram_depth),
                .interface_bits(HALF_DEPTH),
                .LEVEL(LEVEL + 1)
            ) rec_z0 (
                .clk(clk),
                .start(start),
                .a(a_lo),
                .b(b_lo),
                .outf(z0),
                .size(HALF_DEPTH*bram_depth)
            );

            karatsuba_recursive #(
                .base_mult(base_mult),
                .bram_depth(bram_depth),
                .interface_bits(REM_DEPTH),
                .LEVEL(LEVEL + 1)
            ) rec_z2 (
                .clk(clk),
                .start(start),
                .a(a_hi),
                .b(b_hi),
                .outf(z2),
                .size(REM_DEPTH*bram_depth)
            );

            karatsuba_recursive #(
                .base_mult(base_mult),
                .bram_depth(bram_depth),
                .interface_bits(REM_DEPTH+1),
                .LEVEL(LEVEL + 1)
            ) rec_z1 (
                .clk(clk),
                .start(start),
                .a(sum_a),
                .b(sum_b),
                .outf(z1),
                .size((REM_DEPTH+1)*bram_depth)
            );
        end else begin : gen_base
            always @(posedge clk)begin
                z0 <= a_lo * b_lo;
                z2 <= a_hi * b_hi;
                z1 <= sum_a * sum_b;
            end
            // assign z0 = a_lo * b_lo;
            // assign z2 = a_hi * b_hi;
            // assign z1 = sum_a * sum_b;
        end
    endgenerate

    // Final result assembly
    always @(posedge clk) begin
        if (start) begin
            // mid    = z1 - z2 - z0;
            outf <= (z2 << (2*HALF_DEPTH*bram_depth)) + ((z1-z2-z0) << (HALF_DEPTH*bram_depth)) + z0;
            // outf   <= result;
        end
    end
endmodule

module generic_multiplier_karatsuba #(parameter base_mult = 32, parameter interface_bits = 32, parameter bram_depth = 4, parameter MAX_LEVELS = 0)(
    input clk,
    input int size,
    output reg [interface_bits-1:0] out
);
    int num_clocks;
    assign num_clocks = size / interface_bits;
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
    reg [bram_depth*interface_bits-1:0] a = 0;
    reg [bram_depth*interface_bits-1:0] b = 0;
    reg start = 0;
    wire [2*bram_depth*interface_bits:0] outf;
    karatsuba_recursive #(base_mult, bram_depth, interface_bits, 0, MAX_LEVELS) dut(clk, start, a, b, outf, size);

    always @(posedge clk)begin
        if(count % 2 == 1 && count < num_clocks && (num_clocks > 1)) begin
            if (count > 1) begin
                addra[0] <= addra[0] + 1;
                addrb[0] <= addrb[0] + 1;
            end
            else if (count == 1) begin
                addra[0] <= 32'b0;
                addrb[0] <= 32'b0;
            end
        end
        else if ((count % 2 == 0) && (count <= num_clocks) && (num_clocks > 1))begin
            if(count > 2)begin
                addra[1] <= addra[1] + 1;
                addrb[1] <= addrb[1] + 1;
            end
            else if (count == 2) begin
                addra[1] <= 32'b0;
                addrb[1] <= 32'b0;
            end
        end
        else if (count % 2 == 1 && num_clocks <= 1) begin
            addra[0] <= 32'b0;
            addrb[0] <= 32'b0;
        end
        count <= count + 1;
    end
    
    always @(posedge clk) begin
        if (num_clocks > 1) begin
            if(count % 2 == 0 && count < (num_clocks + 4) && count >= 3) begin
                a <= {a, douta[0]};
                b <= {b, doutb[0]};
            end
            else if(count % 2 == 1 && count < (num_clocks + 4) && count >= 4) begin
                a <= {a, douta[1]};
                b <= {b, doutb[1]}; 
            end
            else if (count == num_clocks + 4) begin
                start <= 1;
            end
        end
        else begin
            if (count == 4) begin
                a <= {1'b0, douta[0]};
                b <= {1'b0, doutb[0]};
            end
        end
    end
    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if (count >= 10 && out_idx < 2*size) begin
            out <= outf[out_idx +: interface_bits];
            out_idx <= out_idx + interface_bits;
        end
    end
endmodule