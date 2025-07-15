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

module half_sums #(parameter interface_bits = 32, parameter bram_depth = 128)(
    input start,
    input [interface_bits*bram_depth-1:0] a,
    input [interface_bits-1:0] b,
    output reg [interface_bits*bram_depth*2-1:0] outf
);
    always @(posedge start) begin
        outf = 0;
        for(int i = 0; i < interface_bits; i = i + 1)begin
            if(b[i] == 1)begin
                outf = outf + (a<<i);
            end
        end
    end
endmodule

module traditional_multiplier #(parameter interface_bits = 32, parameter bram_depth = 128)(
    input clk,
    input int size,
    output reg [interface_bits-1:0] out
);
    int num_clocks;
    int count = 0;

    reg [15:0] addra[0:1];
    reg [interface_bits-1:0] dina[0:1];
    reg [interface_bits-1:0] douta[0:1];
    
    reg [15:0] addrb[0:1];
    reg [interface_bits-1:0] dinb[0:1];
    reg [interface_bits-1:0] doutb[0:1];

    reg ena = 1'b1;
    reg ena1 = 1'b1;

    reg [interface_bits*bram_depth-1:0] a = 0;
    reg [interface_bits-1:0] b [0:bram_depth-1];
    
    reg start = 0;
    wire [interface_bits*bram_depth*2-1:0] outf_wires [0:bram_depth-1];
    reg [interface_bits*bram_depth*2-1:0] result = 0;

    genvar p;
    generate
        for(p = 0; p < bram_depth; p = p + 1) begin: MULT_UNITS
            half_sums #(interface_bits, bram_depth) hs_inst (
                // .num_clocks(num_clocks),
                .start(start),
                .a(a),
                .b(b[p]),
                .outf(outf_wires[p])
            );
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
    assign num_clocks = size / interface_bits;
    always @(posedge clk)begin
        // $display("in always block %d", num_clocks);
        if(count % 2 == 1 && count < num_clocks && (num_clocks > 1)) begin
            if (count > 1) begin
                addra[0] <= addra[0] + 1;
                addrb[0] <= addrb[0] + 1;
                // $display("address 1 addition");
            end
            else if (count == 1) begin
                addra[0] <= 32'b0;
                addrb[0] <= 32'b0;
                // $display("default 1");
            end
        end
        else if ((count % 2 == 0) && (count <= num_clocks) && (num_clocks > 1))begin
            if(count > 2)begin
                addra[1] <= addra[1] + 1;
                addrb[1] <= addrb[1] + 1;
                // $display("address 2 addition");
            end
            else if (count == 2) begin
                addra[1] <= 32'b0;
                addrb[1] <= 32'b0;
                // $display("default 2");
            end
        end
        else if (count % 2 == 1 && num_clocks <= 1) begin
            addra[0] <= 32'b0;
            addrb[0] <= 32'b0;
        end
        count <= count + 1;
    end
    int b_idx = 0;
    always @(posedge clk) begin
        if (num_clocks > 1) begin
            if(count % 2 == 0 && count < (num_clocks + 4) && count >= 3) begin
                a <= {a, douta[0]};
                b[b_idx] <= doutb[0];
                b_idx <= b_idx + 1;
            end
            else if(count % 2 == 1 && count < (num_clocks + 4) && count >= 4) begin
                a <= {a, douta[1]};
                b[b_idx] <= doutb[1]; 
                b_idx <= b_idx + 1;
            end
        end
        else begin
            if (count == 4) begin
                a <= {1'b0, douta[0]};
                b[b_idx] <= {1'b0, doutb[0]};
                b_idx <= b_idx + 1;
            end
        end
    end
    
    always @(posedge clk) begin
        if (count >= num_clocks + 4) begin
            start <= 1;
        end
    end
    int idx = 0;
    always @(posedge clk) begin
        if (start && (idx < num_clocks)) begin
            // for(int i = 0; i < num_clocks; i = i + 1) begin
                result <= result + outf_wires[idx];
                idx <= idx + 1;
            // end
        end
    end

    reg [31:0] out_idx = 0;
    always @(posedge clk) begin
        if ((idx == num_clocks) && (out_idx < 2*size)) begin
            out <= result[out_idx +: interface_bits];
            out_idx <= out_idx + interface_bits;
        end
    end
endmodule