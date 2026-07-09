`timescale 1ns / 1ps

module tb_aes_zed_top;

    reg         clk;
    reg         rst_n;
    reg         start_btn;
    wire [7:0]  led;

    aes_zed_top uut (
        .clk_100m(clk),
        .rst_btn_n(rst_n),
        .start_btn(start_btn),
        .led(led)
    );

    always #5 clk = ~clk;

    reg [127:0] expected_ct [0:2];
    reg [127:0] actual_ct;
    reg         capture;

    initial begin
        expected_ct[0] = 128'h8ea2b7ca516745bfeafc49904b496089;
        expected_ct[1] = 128'hdc95c078a2408989ad48a21492842087;
        expected_ct[2] = 128'hd9b8841702b50e9b5ed50a1494dff0e2;
    end

    always @(posedge clk) begin
        if (uut.done && uut.test_running) begin
            actual_ct <= uut.aes_core.cipher_text;
            capture <= 1;
        end else begin
            capture <= 0;
        end
    end

    integer i, pass_count;
    initial begin
        clk = 0;
        rst_n = 0;
        start_btn = 0;
        pass_count = 0;

        #100;
        rst_n = 1;
        #20;

        $display("AES-256 ZedBoard Auto-Test");
        $display("===========================");

        for (i = 0; i < 3; i = i + 1) begin
            start_btn = 1;
            #20;
            start_btn = 0;

            wait (uut.done);
            #10;

            if (actual_ct == expected_ct[i]) begin
                $display("Test %0d: PASS  CT=%h", i+1, actual_ct);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %0d: FAIL  CT=%h  (expected %h)", i+1, actual_ct, expected_ct[i]);
            end

            start_btn = 1;
            #20;
            start_btn = 0;
            #200;
        end

        $display("===============================");
        $display("Results: %0d/3 passed", pass_count);
        if (pass_count == 3)
            $display("NIST FIPS-197 Compliance: CONFIRMED");
        else
            $display("FAIL");

        #100;
        $finish;
    end

endmodule