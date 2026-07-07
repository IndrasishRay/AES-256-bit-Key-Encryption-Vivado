`timescale 1ns / 1ps

module aes_256_pipelined (
    input  wire         clk,
    input  wire         rst,
    input  wire         valid_in,
    input  wire [127:0] plain_text,
    input  wire [255:0] key,
    output wire [127:0] cipher_text,
    output wire         valid_out
);
    wire [1919:0] round_keys_flat;
    aes256_key_expansion_flat keygen (
        .key_in(key),
        .round_keys_flat(round_keys_flat)
    );

    wire [127:0] stage_state [0:14];
    reg  [14:0]  valid_pipe;

    assign stage_state[0] = plain_text ^ round_keys_flat[127:0];

    always @(posedge clk or posedge rst) begin
        if (rst)
            valid_pipe <= 0;
        else
            valid_pipe <= {valid_pipe[13:0], valid_in};
    end

    genvar i;
    generate
        for (i = 1; i < 14; i = i + 1) begin : middle_rounds
            aes_round_stage stage (
                .clk(clk),
                .rst(rst),
                .state_in(stage_state[i-1]),
                .round_key(round_keys_flat[i*128 +: 128]),
                .is_final_round(1'b0),
                .state_out(stage_state[i])
            );
        end
    endgenerate

    aes_round_stage final_stage (
        .clk(clk),
        .rst(rst),
        .state_in(stage_state[13]),
        .round_key(round_keys_flat[14*128 +: 128]),
        .is_final_round(1'b1),
        .state_out(stage_state[14])
    );

    assign cipher_text = stage_state[14];
    assign valid_out = valid_pipe[14];
endmodule
