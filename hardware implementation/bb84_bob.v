`timescale 1ns / 1ps

module bb84_bob (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  photon_in_bit,
    input  wire [7:0]  photon_in_basis,
    output wire [7:0]  bob_basis,      // Bob's measurement bases
    output wire [7:0]  bob_result,     // Bob's measurement results
    output wire        valid
);
    reg [7:0] lfsr_basis;
    reg [7:0] result;
    reg [3:0] count;
    reg       running;

    assign bob_basis = lfsr_basis;
    assign bob_result = result;
    assign valid = running;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_basis <= 8'hEF;
            result <= 0;
            count <= 0;
            running <= 0;
        end else if (!running) begin
            // Start measurement
            running <= 1;
            count <= 0;
        end else if (running) begin
            // Bob's random basis selection
            lfsr_basis <= {lfsr_basis[6:0], lfsr_basis[7] ^ lfsr_basis[5] ^ lfsr_basis[4] ^ lfsr_basis[3]};
            // Measurement: if basis matches, get correct bit; if not, random
            for (i = 0; i < 8; i = i + 1) begin
                if (lfsr_basis[i] == photon_in_basis[i])
                    result[i] <= photon_in_bit[i];
                else
                    result[i] <= lfsr_basis[i]; // random collapse
            end
            count <= count + 1;
            if (count == 7) running <= 0;
        end
    end

    integer i;
endmodule
