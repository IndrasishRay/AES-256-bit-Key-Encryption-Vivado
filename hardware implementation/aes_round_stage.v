`timescale 1ns / 1ps

module aes_round_stage (
    input  wire         clk,
    input  wire         rst,
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    input  wire         is_final_round,
    output reg  [127:0] state_out
);
    wire [127:0] sb_out, sr_out, mc_out;

    subbytes sb (.state_in(state_in), .state_out(sb_out));
    shiftrows sr (.state_in(sb_out), .state_out(sr_out));
    mixcolumns mc (.state_in(sr_out), .state_out(mc_out));

    always @(posedge clk or posedge rst) begin
        if (rst)
            state_out <= 0;
        else if (is_final_round)
            state_out <= sr_out ^ round_key;
        else
            state_out <= mc_out ^ round_key;
    end
endmodule
