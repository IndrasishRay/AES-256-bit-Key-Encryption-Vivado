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
    reg [4:0]   state_cnt;
    reg [1:0]   test_idx;
    reg         test_running;

    assign clk = clk_100m;
    assign rst_n = rst_btn_n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
            plain_text <= 128'h00112233445566778899aabbccddeeff;
            start <= 0;
            state_cnt <= 0;
            test_idx <= 0;
            test_running <= 0;
        end else begin
            case (state_cnt)
                5'd0: begin
                    if (start_btn && !test_running) begin
                        test_idx <= 0;
                        test_running <= 1;
                        state_cnt <= 5'd1;
                    end
                end
                5'd1: begin
                    case (test_idx)
                        0: begin
                            key <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
                            plain_text <= 128'h00112233445566778899aabbccddeeff;
                        end
                        1: begin
                            key <= 256'h0000000000000000000000000000000000000000000000000000000000000000;
                            plain_text <= 128'h00000000000000000000000000000000;
                        end
                        2: begin
                            key <= 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
                            plain_text <= 128'h00112233445566778899aabbccddeeff;
                        end
                    endcase
                    state_cnt <= 5'd2;
                end
                5'd2: begin
                    start <= 1;
                    state_cnt <= 5'd3;
                end
                5'd3: begin
                    start <= 0;
                    state_cnt <= 5'd4;
                end
                5'd4: begin
                    if (done) begin
                        state_cnt <= 5'd5;
                    end
                end
                5'd5: begin
                    if (!start_btn) begin
                        if (test_idx == 2) begin
                            test_running <= 0;
                            state_cnt <= 5'd0;
                        end else begin
                            test_idx <= test_idx + 1;
                            state_cnt <= 5'd1;
                        end
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

    assign led = done ? cipher_text[7:0] : 8'b00000000;

endmodule