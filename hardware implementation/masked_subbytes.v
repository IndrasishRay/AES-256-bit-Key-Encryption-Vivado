`timescale 1ns / 1ps

module masked_subbytes (
    input  wire [127:0] state_in,
    input  wire [127:0] mask_in,
    output wire [127:0] state_out,
    output wire [127:0] mask_out
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : msbox
            masked_sbox ms (
                .in(state_in[i*8 +: 8]),
                .mask_in(mask_in[i*8 +: 8]),
                .out(state_out[i*8 +: 8]),
                .mask_out(mask_out[i*8 +: 8])
            );
        end
    endgenerate
endmodule
