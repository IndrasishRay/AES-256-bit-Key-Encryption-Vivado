`timescale 1ns / 1ps

module inv_mixcolumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    function [7:0] xtime(input [7:0] x);
        xtime = (x << 1) ^ ((x[7]) ? 8'h1b : 8'h00);
    endfunction

    function [7:0] mul(input [7:0] a, input [7:0] b);
        reg [7:0] p;
        integer i;
        begin
            p = 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (b[i]) p = p ^ a;
                a = xtime(a);
            end
            mul = p;
        end
    endfunction

    function [31:0] inv_mix_single_column(input [31:0] col);
        reg [7:0] a0, a1, a2, a3;
        reg [7:0] r0, r1, r2, r3;
        begin
            a0 = col[31:24];
            a1 = col[23:16];
            a2 = col[15:8];
            a3 = col[7:0];

            r0 = mul(a0, 8'h0e) ^ mul(a1, 8'h0b) ^ mul(a2, 8'h0d) ^ mul(a3, 8'h09);
            r1 = mul(a0, 8'h09) ^ mul(a1, 8'h0e) ^ mul(a2, 8'h0b) ^ mul(a3, 8'h0d);
            r2 = mul(a0, 8'h0d) ^ mul(a1, 8'h09) ^ mul(a2, 8'h0e) ^ mul(a3, 8'h0b);
            r3 = mul(a0, 8'h0b) ^ mul(a1, 8'h0d) ^ mul(a2, 8'h09) ^ mul(a3, 8'h0e);

            inv_mix_single_column = {r0, r1, r2, r3};
        end
    endfunction

    wire [7:0] s[0:15];
    assign {
        s[0], s[1], s[2], s[3],
        s[4], s[5], s[6], s[7],
        s[8], s[9], s[10], s[11],
        s[12], s[13], s[14], s[15]
    } = state_in;

    wire [31:0] col_in[0:3];
    assign col_in[0] = {s[0], s[4], s[8], s[12]};
    assign col_in[1] = {s[1], s[5], s[9], s[13]};
    assign col_in[2] = {s[2], s[6], s[10], s[14]};
    assign col_in[3] = {s[3], s[7], s[11], s[15]};

    wire [31:0] col_out[0:3];
    assign col_out[0] = inv_mix_single_column(col_in[0]);
    assign col_out[1] = inv_mix_single_column(col_in[1]);
    assign col_out[2] = inv_mix_single_column(col_in[2]);
    assign col_out[3] = inv_mix_single_column(col_in[3]);

    assign state_out = {
        col_out[0][31:24], col_out[1][31:24], col_out[2][31:24], col_out[3][31:24],
        col_out[0][23:16], col_out[1][23:16], col_out[2][23:16], col_out[3][23:16],
        col_out[0][15:8],  col_out[1][15:8],  col_out[2][15:8],  col_out[3][15:8],
        col_out[0][7:0],   col_out[1][7:0],   col_out[2][7:0],   col_out[3][7:0]
    };
endmodule
