`timescale 1ns / 1ps

module masked_sbox (
    input  wire [7:0] in,
    input  wire [7:0] mask_in,
    output wire [7:0] out,
    output wire [7:0] mask_out
);
    wire [7:0] unmasked = in ^ mask_in;
    wire [7:0] sbox_out;

    sbox_lookup sbox (.in(unmasked), .out(sbox_out));

    assign mask_out = mask_in;
    assign out = sbox_out ^ mask_out;
endmodule
