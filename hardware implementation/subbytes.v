`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2025 13:57:22
// Design Name: 
// Module Name: subbytes
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module subbytes(
    input  wire [127:0] state_in,
    output wire [127:0] state_out
    );
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_loop
            sbox_lookup sbox_inst (
                .in(state_in[i*8 +: 8]),
                .out(state_out[i*8 +: 8])
            );
        end
    endgenerate
    
endmodule
