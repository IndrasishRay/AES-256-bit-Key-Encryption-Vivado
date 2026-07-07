`timescale 1ns / 1ps

module aes_gcm_top (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] plaintext,
    input  wire [95:0]  iv,
    input  wire [255:0] key,
    output wire [127:0] ciphertext,
    output wire [127:0] auth_tag,
    output wire         done
);
    wire [127:0] hash_key;
    wire hk_done;
    aes_256_top h_gen (
        .clk(clk), .rst(rst), .start(start),
        .plain_text(128'h0), .key(key),
        .cipher_text(hash_key), .done(hk_done)
    );

    wire [127:0] aes_ctr_out;
    wire ctr_done;
    aes_256_top ctr_enc (
        .clk(clk), .rst(rst), .start(start),
        .plain_text({iv, 32'h1}), .key(key),
        .cipher_text(aes_ctr_out), .done(ctr_done)
    );
    assign ciphertext = plaintext ^ aes_ctr_out;

    wire [127:0] ghash_out;
    wire ghash_done;
    ghash auth (
        .clk(clk), .rst(rst), .start(ctr_done),
        .data_in(ciphertext), .hash_key(hash_key),
        .hash_out(ghash_out), .done(ghash_done)
    );

    wire [127:0] tag_mask;
    aes_256_top tag_gen (
        .clk(clk), .rst(rst), .start(ctr_done),
        .plain_text({iv, 32'h0}), .key(key),
        .cipher_text(tag_mask), .done()
    );
    assign auth_tag = ghash_out ^ tag_mask;
    assign done = ctr_done;
endmodule
