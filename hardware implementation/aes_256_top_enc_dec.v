`timescale 1ns / 1ps

module aes_256_top_enc_dec (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire         decrypt,     // 0 = encrypt, 1 = decrypt
    input  wire [127:0] data_in,
    input  wire [255:0] key,
    output reg  [127:0] data_out,
    output reg          done
);
    reg [3:0] round;
    reg [127:0] state;

    wire [1919:0] round_keys_flat;
    wire [10:0] round_index = round * 128;
    wire [127:0] round_key = round_keys_flat[round_index +: 128];
    wire [10:0] dec_round_index = (14 - round) * 128;
    wire [127:0] dec_round_key = round_keys_flat[dec_round_index +: 128];

    aes256_key_expansion_flat keygen (
        .key_in(key),
        .round_keys_flat(round_keys_flat)
    );

    wire [127:0] sb_out, sr_out, mc_out;
    subbytes sb (.state_in(state), .state_out(sb_out));
    shiftrows sr (.state_in(sb_out), .state_out(sr_out));
    mixcolumns mc (.state_in(sr_out), .state_out(mc_out));

    wire [127:0] isb_out, isr_out, imc_out;
    inv_subbytes isb (.state_in(state), .state_out(isb_out));
    inv_shiftrows isr (.state_in(isb_out), .state_out(isr_out));
    inv_mixcolumns imc (.state_in(isr_out), .state_out(imc_out));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round <= 0;
            done <= 0;
            data_out <= 0;
            state <= 0;
        end else if (start && round == 0 && !done) begin
            state <= data_in ^ (decrypt ? dec_round_key : round_key);
            data_out <= 0;
            done <= 0;
            round <= 1;
        end else if (round > 0 && round < 14) begin
            if (decrypt)
                state <= imc_out ^ dec_round_key;
            else
                state <= mc_out ^ round_key;
            round <= round + 1;
        end else if (round == 14) begin
            if (decrypt)
                data_out <= isr_out ^ dec_round_key;
            else
                data_out <= sr_out ^ round_key;
            done <= 1;
            round <= 0;
        end else begin
            done <= 0;
        end
    end
endmodule
