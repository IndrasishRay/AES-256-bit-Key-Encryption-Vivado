`timescale 1ns / 1ps

module eve_detector (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  alice_basis,
    input  wire [7:0]  bob_basis,
    input  wire [7:0]  bob_result,
    input  wire [7:0]  alice_bit,
    output reg  [3:0]  error_rate,     // errors per 8 bits (0-8)
    output reg         eve_detected,
    output reg         key_valid,
    output reg [7:0]   sifted_key
);
    reg [3:0] errors;
    reg [7:0] key;
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            error_rate <= 0;
            eve_detected <= 0;
            key_valid <= 0;
            sifted_key <= 0;
        end else if (start) begin
            errors <= 0;
            key <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (alice_basis[i] == bob_basis[i]) begin
                    // Matching basis: keep this bit for key
                    key[i] <= alice_bit[i];
                    // Check if Eve corrupted it
                    if (bob_result[i] != alice_bit[i])
                        errors <= errors + 1;
                end else begin
                    // Non-matching basis: discard (sifting)
                    key[i] <= 0;
                end
            end
            // Eve detection: if error rate > 25%, Eve is intercepting
            // In BB84, ~25% error = intercept-resend attack
            if (errors > 2)
                eve_detected <= 1;
            else
                eve_detected <= 0;
            error_rate <= errors;
            key_valid <= 1;
            sifted_key <= key;
        end
    end
endmodule
