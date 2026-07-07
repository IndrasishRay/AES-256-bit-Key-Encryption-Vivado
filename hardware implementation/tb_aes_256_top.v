`timescale 1ns / 1ps

module tb_aes_256_top;
    reg         clk;
    reg         rst;
    reg         start;
    reg  [127:0] plain_text;
    reg  [255:0] key;
    wire [127:0] cipher_text;
    wire         done;

    aes_256_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .plain_text(plain_text),
        .key(key),
        .cipher_text(cipher_text),
        .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg [127:0] expected_ct;
    integer pass_count;
    integer fail_count;
    integer test_num;

    task run_test;
        input [127:0] pt;
        input [255:0] k;
        input [127:0] expected;
        begin
            test_num = test_num + 1;
            @(posedge clk);
            plain_text = pt;
            key = k;
            expected_ct = expected;
            start = 1;
            @(posedge clk);
            start = 0;
            wait (done == 1);
            @(posedge clk);
            if (cipher_text === expected_ct) begin
                $display("TEST %0d: PASS  CT=%032h", test_num, cipher_text);
                pass_count = pass_count + 1;
            end else begin
                $display("TEST %0d: FAIL", test_num);
                $display("  Expected: %032h", expected_ct);
                $display("  Got:      %032h", cipher_text);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        rst = 1; start = 0; plain_text = 0; key = 0;
        pass_count = 0; fail_count = 0; test_num = 0;
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // NIST FIPS-197 Appendix C.2 — AES-256 Test Vector 1
        run_test(
            128'h00112233_44556677_8899aabb_ccddeeff,
            256'h00010203_04050607_08090a0b_0c0d0e0f_10111213_14151617_18191a1b_1c1d1e1f,
            128'h8ea2b7ca_516745bf_eafc4990_4b496089
        );

        // NIST FIPS-197 Appendix C.2 — AES-256 Test Vector 2
        run_test(
            128'h00000000_00000000_00000000_00000000,
            256'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
            128'hdc95c078_a2408989_ad48a214_92842087
        );

        // NIST FIPS-197 Appendix C.2 — AES-256 Test Vector 3
        run_test(
            128'h00112233_44556677_8899aabb_ccddeeff,
            256'hffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff,
            128'hd9b88417_02b50e9b_5ed50a14_94dff0e2
        );

        $display("-------------------");
        $display("Results: %0d passed, %0d failed", pass_count, fail_count);
        $display("-------------------");
        #100;
        $finish;
    end

    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
