`timescale 1ns / 1ps

module ghash (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] data_in,
    input  wire [127:0] hash_key,
    output reg  [127:0] hash_out,
    output reg          done
);
    function [127:0] gf_mult;
        input [127:0] a, b;
        reg [127:0] p;
        integer i;
        begin
            p = 0;
            for (i = 0; i < 128; i = i + 1) begin
                if (b[i]) p = p ^ a;
                a = {a[126:0], 1'b0} ^ (a[127] ? 128'h87 : 128'h0);
            end
            gf_mult = p;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hash_out <= 0;
            done <= 0;
        end else if (start) begin
            hash_out <= gf_mult(hash_out ^ data_in, hash_key);
            done <= 1;
        end else begin
            done <= 0;
        end
    end
endmodule
