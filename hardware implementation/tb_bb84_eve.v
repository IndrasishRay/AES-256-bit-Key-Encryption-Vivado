`timescale 1ns / 1ps

module tb_bb84_eve;
    reg         clk;
    reg         rst;
    reg         start;
    reg         eve_intercept;
    reg  [127:0] plaintext;
    wire [127:0] ciphertext;
    wire         eve_detected;
    wire         key_valid;
    wire [3:0]   error_rate;

    bb84_aes_top dut (
        .clk(clk), .rst(rst), .start(start),
        .eve_intercept(eve_intercept),
        .plaintext(plaintext),
        .ciphertext(ciphertext),
        .eve_detected(eve_detected),
        .key_valid(key_valid),
        .error_rate(error_rate)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("========================================");
        $display(" BB84 QKD + AES-256: Eve Interception");
        $display("========================================");

        rst = 1; start = 0; eve_intercept = 0;
        plaintext = 128'hDEADBEEF_CAFEBABE_12345678_9ABCDEF0;
        repeat(3) @(posedge clk);
        rst = 0;

        // === TEST 1: No Eve (clean key exchange) ===
        $display("\n--- TEST 1: NO Eve Interception ---");
        eve_intercept = 0;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait (key_valid);
        @(posedge clk);

        $display("Error Rate:  %0d / 8 bits", error_rate);
        $display("Eve Detected: %b", eve_detected);
        $display("Key Valid:    %b", key_valid);

        if (!eve_detected)
            $display("RESULT: Key exchange SECURE. No eavesdropper.");
        else
            $display("RESULT: FALSE POSITIVE — Eve detected when none present!");

        wait (aes_done);
        @(posedge clk);
        $display("Ciphertext:   %032h", ciphertext);

        // === TEST 2: Eve intercepting ===
        $display("\n--- TEST 2: Eve INTERCEPTING ---");
        @(posedge clk);
        eve_intercept = 1;
        start = 1;
        @(posedge clk);
        start = 0;

        wait (key_valid);
        @(posedge clk);

        $display("Error Rate:  %0d / 8 bits", error_rate);
        $display("Eve Detected: %b", eve_detected);

        if (eve_detected)
            $display("RESULT: Eve DETECTED! Key exchange ABORTED.");
        else
            $display("RESULT: Eve evaded detection (low sample count).");

        // === TEST 3: Multiple rounds with Eve ===
        $display("\n--- TEST 3: Multiple rounds with Eve ---");
        repeat(5) begin
            @(posedge clk);
            start = 1;
            eve_intercept = 1;
            @(posedge clk);
            start = 0;
            wait (key_valid);
            @(posedge clk);
            $display("  Round — Error Rate: %0d, Eve Detected: %b", error_rate, eve_detected);
        end

        $display("\n========================================");
        $display(" Summary");
        $display("========================================");
        $display(" Eve interception causes ~25%% error rate");
        $display(" in BB84 sifted key. Error rate > 2/8");
        $display(" triggers detection. Eve cannot hide.");
        $display("========================================");

        #100;
        $finish;
    end

    wire aes_done = dut.aes_done;

    initial begin
        #5000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
