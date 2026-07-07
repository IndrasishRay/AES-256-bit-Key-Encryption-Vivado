`timescale 1ns / 1ps

module bb84_alice (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire [7:0]  photon_bit,     // secret bit encoded
    output wire [7:0]  photon_basis,   // 0=rectilinear(⊕), 1=diagonal(⊗)
    output wire        valid,
    output wire [7:0]  alice_basis     // kept private, shared later for sifting
);
    reg [7:0] lfsr_bit;
    reg [7:0] lfsr_basis;
    reg [3:0] count;
    reg       running;

    assign photon_bit = lfsr_bit;
    assign photon_basis = lfsr_basis;
    assign alice_basis = lfsr_basis;
    assign valid = running;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_bit <= 8'hAB;
            lfsr_basis <= 8'hCD;
            count <= 0;
            running <= 0;
        end else if (start && !running) begin
            running <= 1;
            count <= 0;
        end else if (running) begin
            // LFSR for random bit generation (polynomial: x^8 + x^6 + x^5 + x^4 + 1)
            lfsr_bit <= {lfsr_bit[6:0], lfsr_bit[7] ^ lfsr_bit[5] ^ lfsr_bit[4] ^ lfsr_bit[3]};
            lfsr_basis <= {lfsr_basis[6:0], lfsr_basis[7] ^ lfsr_basis[5] ^ lfsr_basis[4] ^ lfsr_basis[2]};
            count <= count + 1;
            if (count == 7) running <= 0;
        end
    end
endmodule
