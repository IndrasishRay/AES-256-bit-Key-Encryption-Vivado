`timescale 1ns / 1ps

module bb84_aes_top (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire         eve_intercept,  // toggle Eve on/off
    input  wire [127:0] plaintext,
    output wire [127:0] ciphertext,
    output wire         eve_detected,
    output wire         key_valid,
    output wire [3:0]   error_rate
);
    wire [7:0] alice_photon_bit, alice_photon_basis, alice_basis;
    wire       alice_valid;

    wire [7:0] eve_out_bit, eve_out_basis;
    wire       eve_intercepted;
    wire [3:0] eve_error_count;

    wire [7:0] bob_basis, bob_result;
    wire       bob_valid;

    wire [7:0] sifted_key;
    wire       detection_done;

    wire [255:0] aes_key;
    assign aes_key = {{24{sifted_key[7]}}, sifted_key,
                      {24{sifted_key[6]}}, sifted_key,
                      {24{sifted_key[5]}}, sifted_key,
                      {24{sifted_key[4]}}, sifted_key,
                      {24{sifted_key[3]}}, sifted_key,
                      {24{sifted_key[2]}}, sifted_key,
                      {24{sifted_key[1]}}, sifted_key,
                      {24{sifted_key[0]}}, sifted_key};

    bb84_alice alice (
        .clk(clk), .rst(rst), .start(start),
        .photon_bit(alice_photon_bit),
        .photon_basis(alice_photon_basis),
        .valid(alice_valid),
        .alice_basis(alice_basis)
    );

    bb84_eve eve (
        .clk(clk), .rst(rst),
        .intercept(eve_intercept),
        .photon_in_bit(alice_photon_bit),
        .photon_in_basis(alice_photon_basis),
        .photon_out_bit(eve_out_bit),
        .photon_out_basis(eve_out_basis),
        .intercepted(eve_intercepted),
        .error_count(eve_error_count)
    );

    wire [7:0] bob_photon_in_bit = eve_intercept ? eve_out_bit : alice_photon_bit;
    wire [7:0] bob_photon_in_basis = eve_intercept ? eve_out_basis : alice_photon_basis;

    bb84_bob bob (
        .clk(clk), .rst(rst),
        .photon_in_bit(bob_photon_in_bit),
        .photon_in_basis(bob_photon_in_basis),
        .bob_basis(bob_basis),
        .bob_result(bob_result),
        .valid(bob_valid)
    );

    eve_detector detector (
        .clk(clk), .rst(rst),
        .start(bob_valid),
        .alice_basis(alice_basis),
        .bob_basis(bob_basis),
        .bob_result(bob_result),
        .alice_bit(alice_photon_bit),
        .error_rate(error_rate),
        .eve_detected(eve_detected),
        .key_valid(key_valid),
        .sifted_key(sifted_key)
    );

    reg  aes_start;
    wire [127:0] aes_out;
    wire         aes_done;

    always @(posedge clk or posedge rst) begin
        if (rst)
            aes_start <= 0;
        else if (key_valid && !eve_detected)
            aes_start <= 1;
        else
            aes_start <= 0;
    end

    aes_256_top aes (
        .clk(clk), .rst(rst), .start(aes_start),
        .plain_text(plaintext),
        .key(aes_key),
        .cipher_text(aes_out),
        .done(aes_done)
    );

    assign ciphertext = aes_out;
endmodule
