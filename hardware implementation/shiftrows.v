`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2025 14:19:01
// Design Name: 
// Module Name: shiftrows
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


module shiftrows (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    wire [7:0] s[0:15];

    assign {
        s[0],  s[4],  s[8],  s[12],   // Row 0
        s[1],  s[5],  s[9],  s[13],   // Row 1
        s[2],  s[6],  s[10], s[14],   // Row 2
        s[3],  s[7],  s[11], s[15]    // Row 3
    } = state_in;

    wire [7:0] sr[0:15];

    // Apply shift
    assign sr[0]  = s[0];
    assign sr[4]  = s[4];
    assign sr[8]  = s[8];
    assign sr[12] = s[12];

    assign sr[1]  = s[5];
    assign sr[5]  = s[9];
    assign sr[9]  = s[13];
    assign sr[13] = s[1];

    assign sr[2]  = s[10];
    assign sr[6]  = s[14];
    assign sr[10] = s[2];
    assign sr[14] = s[6];

    assign sr[3]  = s[15];
    assign sr[7]  = s[3];
    assign sr[11] = s[7];
    assign sr[15] = s[11];

    assign state_out = {
        sr[0], sr[4], sr[8],  sr[12],
        sr[1], sr[5], sr[9],  sr[13],
        sr[2], sr[6], sr[10], sr[14],
        sr[3], sr[7], sr[11], sr[15]
    };
endmodule

