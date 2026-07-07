`timescale 1ns / 1ps

module bb84_eve (
    input  wire        clk,
    input  wire        rst,
    input  wire        intercept,      // enable interception
    input  wire [7:0]  photon_in_bit,
    input  wire [7:0]  photon_in_basis,
    output wire [7:0]  photon_out_bit,     // bit sent to Bob (may be corrupted)
    output wire [7:0]  photon_out_basis,   // basis Eve used (for analysis)
    output wire        intercepted,
    output wire [3:0]  error_count         // errors introduced this round
);
    reg [7:0] eve_basis;
    reg [3:0] err_cnt;
    integer i;

    assign intercepted = intercept;
    assign photon_out_basis = eve_basis;
    assign error_count = err_cnt;

    // Eve's photon_out_bit: corrupted if she guessed wrong basis
    reg [7:0] out_bit;
    assign photon_out_bit = out_bit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            eve_basis <= 8'h00;
            err_cnt <= 0;
            out_bit <= 0;
        end else if (intercept) begin
            // Eve guesses bases randomly (LFSR)
            eve_basis <= {eve_basis[6:0], eve_basis[7] ^ eve_basis[5] ^ eve_basis[4] ^ eve_basis[2]};
            err_cnt <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (eve_basis[i] != photon_in_basis[i]) begin
                    // Wrong basis: measurement collapses photon randomly
                    // 50% chance of flipping the bit
                    out_bit[i] <= ~photon_in_bit[i];
                    err_cnt <= err_cnt + 1;
                end else begin
                    // Correct basis: bit passes through unchanged
                    out_bit[i] <= photon_in_bit[i];
                end
            end
        end
    end
endmodule
