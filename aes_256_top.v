`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2025 13:30:02
// Design Name: 
// Module Name: aes_256_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module aes_256_top(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] plain_text,
    input  wire [255:0] key,
    output reg  [127:0] cipher_text,
    output reg          done
);

    reg [3:0] round;
    reg [127:0] state;
    wire [1919:0] round_keys_flat;
    wire [10:0] round_index = round * 128;
    wire [127:0] round_key = round_keys_flat[round_index +: 128];

    aes256_key_expansion_flat keygen (
        .key_in(key),
        .round_keys_flat(round_keys_flat)
    );

    wire [127:0] sb_out, sr_out, mc_out;

    subbytes sb (
        .state_in(state),
        .state_out(sb_out)
    );

    shiftrows sr (
        .state_in(sb_out),
        .state_out(sr_out)
    );

    mixcolumns mc (
        .state_in(sr_out),
        .state_out(mc_out)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round <= 0;
            done <= 0;
            cipher_text <= 0;
            state <= 0;
        end else if (start && round == 0 && !done) begin
            state <= plain_text ^ round_key;
            cipher_text <= 0;
            done <= 0;
            round <= 1;
        end else if (round > 0 && round < 14) begin
            state <= mc_out ^ round_key;
            round <= round + 1;
        end else if (round == 14) begin
            cipher_text <= sr_out ^ round_key;
            done <= 1;
            round <= 0;
        end else begin
            done <= 0;
        end
    end

endmodule
