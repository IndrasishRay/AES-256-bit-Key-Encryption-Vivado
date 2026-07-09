`timescale 1ns / 1ps

module aes_zed_top (
    input  wire         clk_100m,
    input  wire         rst_btn_n,
    input  wire         start_btn,
    output wire [7:0]   led
);

    wire         clk;
    wire         rst_n;
    wire [127:0] cipher_text;
    wire         done;

    reg [255:0] key;
    reg [127:0] plain_text;
    reg         start;
    reg [3:0]   state_cnt;
    reg         start_done;

    assign clk = clk_100m;
    assign rst_n = rst_btn_n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
            plain_text <= 128'h00112233445566778899aabbccddeeff;
            start <= 0;
            state_cnt <= 0;
            start_done <= 0;
        end else begin
            case (state_cnt)
                4'd0: begin
                    if (start_btn && !start_done) begin
                        start <= 1;
                        state_cnt <= 4'd1;
                    end
                end
                4'd1: begin
                    start <= 0;
                    state_cnt <= 4'd2;
                end
                4'd2: begin
                    if (done) begin
                        start_done <= 1;
                        state_cnt <= 4'd3;
                    end
                end
                4'd3: begin
                    if (!start_btn) begin
                        start_done <= 0;
                        state_cnt <= 4'd0;
                    end
                end
            endcase
        end
    end

    aes_256_top aes_core (
        .clk(clk),
        .rst(~rst_n),
        .start(start),
        .plain_text(plain_text),
        .key(key),
        .cipher_text(cipher_text),
        .done(done)
    );

    assign led = done ? 8'b11111111 : cipher_text[7:0];

endmodule