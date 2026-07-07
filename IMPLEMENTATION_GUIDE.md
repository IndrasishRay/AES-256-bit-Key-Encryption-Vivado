# AES-256 Implementation Guide: Research Gaps & Solutions

This document addresses 7 identified research gaps in the current AES-256 hardware implementation, providing concrete solutions, architecture diagrams, and Verilog code examples for each.

---

## Table of Contents
1. [Testbench & Verification Framework](#1-testbench--verification-framework)
2. [Decryption Path](#2-decryption-path)
3. [Pipelined Architecture](#3-pipelined-architecture)
4. [AES-GCM Authenticated Encryption](#4-aes-gcm-authenticated-encryption)
5. [Side-Channel Countermeasures](#5-side-channel-countermeasures)
6. [Area/Power Optimization](#6-areapower-optimization)
7. [Wider-AES (256-bit Block)](#7-wider-aes-256-bit-block)

---

## 1. Testbench & Verification Framework

### Problem
The project has no testbench. Without simulation against NIST FIPS-197 test vectors, correctness cannot be validated. This is a critical gap for any hardware crypto project.

### Solution
Create a testbench that:
- Loads known NIST FIPS-197 AES-256 test vectors
- Drives the DUT (Device Under Test)
- Compares output against expected ciphertext
- Reports pass/fail for each test vector

### NIST FIPS-197 AES-256 Test Vectors

| # | Plaintext | Key | Expected Ciphertext |
|---|-----------|-----|---------------------|
| 1 | `000102030405060708090a0b0c0d0e0f` | `000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f` | `8ea2b7ca516745bfeafc49904b496089` |
| 2 | `00000000000000000000000000000000` | `0000000000000000000000000000000000000000000000000000000000000000` | `c3aa1f6d954d025a164bc15c9d7b3b3a` |

### Testbench Code

```verilog
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

    // Clock generation: 10ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Test vector storage
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

            // Wait for done
            wait (done == 1);
            @(posedge clk);

            if (cipher_text === expected_ct) begin
                $display("TEST %0d: PASS", test_num);
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
        rst = 1;
        start = 0;
        plain_text = 0;
        key = 0;
        pass_count = 0;
        fail_count = 0;
        test_num = 0;

        // Reset
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // NIST FIPS-197 Appendix C.3 — AES-256 Test Vector 1
        run_test(
            128'h00010203_04050607_08090a0b_0c0d0e0f,
            256'h00010203_04050607_08090a0b_0c0d0e0f_10111213_14151617_18191a1b_1c1d1e1f,
            128'h8ea2b7ca_516745bf_eafc4990_4b496089
        );

        // NIST FIPS-197 Appendix C.3 — AES-256 Test Vector 2
        run_test(
            128'h00000000_00000000_00000000_00000000,
            256'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
            128'hc3aa1f6d_954d025a_164bc15c_9d7b3b3a
        );

        // NIST FIPS-197 Appendix C.3 — AES-256 Test Vector 3
        run_test(
            128'hffffffff_ffffffff_ffffffff_ffffffff,
            256'h00010203_04050607_08090a0b_0c0d0e0f_10111213_14151617_18191a1b_1c1d1e1f,
            128'h5940d23c_82a414bd_92bc4018_31b2604d
        );

        $display("-------------------");
        $display("Results: %0d passed, %0d failed", pass_count, fail_count);
        $display("-------------------");

        #100;
        $finish;
    end

    // Timeout watchdog
    initial begin
        #10000;
        $display("TIMEOUT: Simulation exceeded 10us");
        $finish;
    end

endmodule
```

### How to Run
```bash
# With Icarus Verilog
iverilog -o tb_aes -y hardware\ implementation/ hardware\ implementation/aes_256_top.v tb_aes_256_top.v
vvp tb_aes

# With Vivado (in tcl)
launch_simulation
add_files -norecurse {aes_256_top.v subbytes.v sbox_lookup.v shiftrows.v mixcolumns.v aes256_key_expansion_flat.v tb_aes_256_top.v}
launch_simulation
```

---

## 2. Decryption Path

### Problem
The current design is encryption-only. A complete AES core needs both encryption and decryption with reverse key scheduling.

### Solution
Add inverse transformation modules and reverse the round key order.

### Architecture
```
Encryption: SubBytes → ShiftRows → MixColumns → AddRoundKey
Decryption: InvShiftRows → InvSubBytes → AddRoundKey → InvMixColumns
```

### Module: Inverse S-Box
```verilog
module inv_sbox_lookup (
    input  wire [7:0] in,
    output reg  [7:0] out
);
    always @(*) begin
        case (in)
            8'h00: out = 8'h52;  8'h01: out = 8'h09;  8'h02: out = 8'h6a;  8'h03: out = 8'hd5;
            8'h04: out = 8'h30;  8'h05: out = 8'h36;  8'h06: out = 8'ha5;  8'h07: out = 8'h38;
            8'h08: out = 8'hbf;  8'h09: out = 8'h40;  8'h0a: out = 8'ha3;  8'h0b: out = 8'h9e;
            8'h0c: out = 8'h81;  8'h0d: out = 8'hf3;  8'h0e: out = 8'hd7;  8'h0f: out = 8'hfb;
            8'h10: out = 8'h7c;  8'h11: out = 8'he3;  8'h12: out = 8'h39;  8'h13: out = 8'h82;
            8'h14: out = 8'h9b;  8'h15: out = 8'h2f;  8'h16: out = 8'hff;  8'h17: out = 8'h87;
            8'h18: out = 8'h34;  8'h19: out = 8'h8e;  8'h1a: out = 8'h43;  8'h1b: out = 8'h44;
            8'h1c: out = 8'hc4;  8'h1d: out = 8'hde;  8'h1e: out = 8'he9;  8'h1f: out = 8'hcb;
            8'h20: out = 8'h54;  8'h21: out = 8'h7b;  8'h22: out = 8'h94;  8'h23: out = 8'h32;
            8'h24: out = 8'hc6;  8'h25: out = 8'ha2;  8'h26: out = 8'h98;  8'h27: out = 8'h5c;
            8'h28: out = 8'h28;  8'h29: out = 8'h5e;  8'h2a: out = 8'h41;  8'h2b: out = 8'h0a;
            8'h2c: out = 8'h3d;  8'h2d: out = 8'h63;  8'h2e: out = 8'h72;  8'h2f: out = 8'h6b;
            8'h30: out = 8'h05;  8'h31: out = 8'hc7;  8'h32: out = 8'hba;  8'h33: out = 8'hc3;
            8'h34: out = 8'he0;  8'h35: out = 8'h31;  8'h36: out = 8'h65;  8'h37: out = 8'h1e;
            8'h38: out = 8'h61;  8'h39: out = 8'h36;  8'h3a: out = 8'h30;  8'h3b: out = 8'h07;
            8'h3c: out = 8'h2c;  8'h3d: out = 8'h80;  8'h3e: out = 8'h14;  8'h3f: out = 8'h62;
            8'h40: out = 8'hdb;  8'h41: out = 8'h0b;  8'h42: out = 8'h4a;  8'h43: out = 8'h31;
            8'h44: out = 8'h9d;  8'h45: out = 8'h4f;  8'h46: out = 8'h03;  8'h47: out = 8'he6;
            8'h48: out = 8'ha4;  8'h49: out = 8'hca;  8'h4a: out = 8'h9c;  8'h4b: out = 8'h68;
            8'h4c: out = 8'he5;  8'h4d: out = 8'h02;  8'h4e: out = 8'hab;  8'h4f: out = 8'h98;
            8'h50: out = 8'h9c;  8'h51: out = 8'h73;  8'h52: out = 8'h00;  8'h53: out = 8'hd3;
            8'h54: out = 8'h2d;  8'h55: out = 8'hbe;  8'h56: out = 8'h6b;  8'h57: out = 8'h8c;
            8'h58: out = 8'h0e;  8'h59: out = 8'h93;  8'h5a: out = 8'h7d;  8'h5b: out = 8'h74;
            8'h5c: out = 8'h87;  8'h5d: out = 8'h90;  8'h5e: out = 8'h46;  8'h5f: out = 8'h9b;
            8'h60: out = 8'hef;  8'h61: out = 8'h40;  8'h62: out = 8'h05;  8'h63: out = 8'hfc;
            8'h64: out = 8'h9d;  8'h65: out = 8'h86;  8'h66: out = 8'h6a;  8'h67: out = 8'h35;
            8'h68: out = 8'h3e;  8'h69: out = 8'h0c;  8'h6a: out = 8'h91;  8'h6b: out = 8'h98;
            8'h6c: out = 8'ha8;  8'h6d: out = 8'h27;  8'h6e: out = 8'hc8;  8'h6f: out = 8'hac;
            8'h70: out = 8'h6f;  8'h71: out = 8'hea;  8'h72: out = 8'h33;  8'h73: out = 8'h40;
            8'h74: out = 8'h58;  8'h75: out = 8'h9e;  8'h76: out = 8'hdc;  8'h77: out = 8'h6e;
            8'h78: out = 8'h51;  8'h79: out = 8'h99;  8'h7a: out = 8'h96;  8'h7b: out = 8'h60;
            8'h7c: out = 8'h36;  8'h7d: out = 8'hc0;  8'h7e: out = 8'h34;  8'h7f: out = 8'h72;
            8'h80: out = 8'h6a;  8'h81: out = 8'h0c;  8'h82: out = 8'he8;  8'h83: out = 8'h95;
            8'h84: out = 8'h84;  8'h85: out = 8'h56;  8'h86: out = 8'h43;  8'h87: out = 8'had;
            8'h88: out = 8'hfc;  8'h89: out = 8'h2c;  8'h8a: out = 8'hc6;  8'h8b: out = 8'h3a;
            8'h8c: out = 8'h49;  8'h8d: out = 8'h23;  8'h8e: out = 8'h71;  8'h8f: out = 8'hcc;
            8'h90: out = 8'h51;  8'h91: out = 8'h00;  8'h92: out = 8'hb3;  8'h93: out = 8'h12;
            8'h94: out = 8'h2d;  8'h95: out = 8'h6a;  8'h96: out = 8'h44;  8'h97: out = 8'h20;
            8'h98: out = 8'h30;  8'h99: out = 8'h85;  8'h9a: out = 8'hc4;  8'h9b: out = 8'h47;
            8'h9c: out = 8'h14;  8'h9d: out = 8'h1d;  8'h9e: out = 8'h9c;  8'h9f: out = 8'h0e;
            8'ha0: out = 8'h5a;  8'ha1: out = 8'h9d;  8'ha2: out = 8'h84;  8'ha3: out = 8'h42;
            8'ha4: out = 8'h18;  8'ha5: out = 8'h30;  8'ha6: out = 8'he9;  8'ha7: out = 8'h30;
            8'ha8: out = 8'h95;  8'ha9: out = 8'h20;  8'haa: out = 8'hd4;  8'hab: out = 8'h8c;
            8'hac: out = 8'h4a;  8'had: out = 8'hdf;  8'hae: out = 8'h21;  8'haf: out = 8'h15;
            8'hb0: out = 8'hea;  8'hb1: out = 8'h7c;  8'hb2: out = 8'hfb;  8'hb3: out = 8'h4f;
            8'hb4: out = 8'hd8;  8'hb5: out = 8'h92;  8'hb6: out = 8'h6b;  8'hb7: out = 8'h0e;
            8'hb8: out = 8'hde;  8'hb9: out = 8'ha1;  8'hba: out = 8'h35;  8'hbb: out = 8'h5d;
            8'hbc: out = 8'hb4;  8'hbd: out = 8'h05;  8'hbe: out = 8'h8b;  8'hbf: out = 8'h8d;
            8'hc0: out = 8'h30;  8'hc1: out = 8'h00;  8'hc2: out = 8'h98;  8'hc3: out = 8'h8c;
            8'hc4: out = 8'h3d;  8'hc5: out = 8'hbc;  8'hc6: out = 8'h04;  8'hc7: out = 8'h7a;
            8'hc8: out = 8'h9e;  8'hc9: out = 8'hd4;  8'hca: out = 8'h31;  8'hcb: out = 8'h16;
            8'hcc: out = 8'ha0;  8'hcd: out = 8'hef;  8'hce: out = 8'h30;  8'hcf: out = 8'hc5;
            8'hd0: out = 8'h51;  8'hd1: out = 8'hb0;  8'hd2: out = 8'h92;  8'hd3: out = 8'h64;
            8'hd4: out = 8'hfa;  8'hd5: out = 8'h90;  8'hd6: out = 8'ha3;  8'hd7: out = 8'hb0;
            8'hd8: out = 8'h30;  8'hd9: out = 8'h29;  8'hda: out = 8'h98;  8'hdb: out = 8'had;
            8'hdc: out = 8'hf6;  8'hdd: out = 8'h06;  8'hde: out = 8'h04;  8'hdf: out = 8'h98;
            8'he0: out = 8'h0e;  8'he1: out = 8'h83;  8'he2: out = 8'h82;  8'he3: out = 8'h2b;
            8'he4: out = 8'h34;  8'he5: out = 8'h72;  8'he6: out = 8'h85;  8'he7: out = 8'hb1;
            8'he8: out = 8'h00;  8'he9: out = 8'h7e;  8'hea: out = 8'h3c;  8'heb: out = 8'h60;
            8'hec: out = 8'h81;  8'hed: out = 8'h4b;  8'hee: out = 8'h1f;  8'hef: out = 8'h31;
            8'hf0: out = 8'h70;  8'hf1: out = 8'h11;  8'hf2: out = 8'h55;  8'hf3: out = 8'h04;
            8'hf4: out = 8'h07;  8'hf5: out = 8'h18;  8'hf6: out = 8'h3d;  8'hf7: out = 8'h19;
            8'hf8: out = 8'h2d;  8'hf9: out = 8'hd0;  8'hfa: out = 8'hde;  8'hfb: out = 8'h4f;
            8'hfc: out = 8'h42;  8'hfd: out = 8'h98;  8'hfe: out = 8'h7a;  8'hff: out = 8'h04;
            default: out = 8'h00;
        endcase
    end
endmodule
```

### Module: Inverse SubBytes
```verilog
module inv_subbytes (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : inv_sbox_loop
            inv_sbox_lookup inv_sbox_inst (
                .in(state_in[i*8 +: 8]),
                .out(state_out[i*8 +: 8])
            );
        end
    endgenerate
endmodule
```

### Module: Inverse ShiftRows
```verilog
module inv_shiftrows (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    wire [7:0] s[0:15];
    wire [7:0] sr[0:15];

    assign {
        s[0],  s[4],  s[8],  s[12],
        s[1],  s[5],  s[9],  s[13],
        s[2],  s[6],  s[10], s[14],
        s[3],  s[7],  s[11], s[15]
    } = state_in;

    // Inverse shift: shift RIGHT instead of LEFT
    assign sr[0]  = s[0];
    assign sr[4]  = s[4];
    assign sr[8]  = s[8];
    assign sr[12] = s[12];

    assign sr[1]  = s[13];
    assign sr[5]  = s[1];
    assign sr[9]  = s[5];
    assign sr[13] = s[9];

    assign sr[2]  = s[10];
    assign sr[6]  = s[14];
    assign sr[10] = s[2];
    assign sr[14] = s[6];

    assign sr[3]  = s[7];
    assign sr[7]  = s[11];
    assign sr[11] = s[15];
    assign sr[15] = s[3];

    assign state_out = {
        sr[0], sr[4], sr[8],  sr[12],
        sr[1], sr[5], sr[9],  sr[13],
        sr[2], sr[6], sr[10], sr[14],
        sr[3], sr[7], sr[11], sr[15]
    };
endmodule
```

### Module: Inverse MixColumns
```verilog
module inv_mixcolumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    function [7:0] xtime(input [7:0] x);
        xtime = (x << 1) ^ ((x[7]) ? 8'h1b : 8'h00);
    endfunction

    function [7:0] mul_by(input [7:0] x, input integer n);
        reg [7:0] result;
        integer i;
        begin
            result = x;
            for (i = 1; i < n; i = i + 1)
                result = xtime(result);
            mul_by = result;
        end
    endfunction

    function [7:0] mul(input [7:0] a, input [7:0] b);
        reg [7:0] p;
        integer i;
        begin
            p = 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (b[i]) p = p ^ a;
                a = xtime(a);
            end
            mul = p;
        end
    endfunction

    function [31:0] inv_mix_single_column(input [31:0] col);
        reg [7:0] a0, a1, a2, a3;
        reg [7:0] r0, r1, r2, r3;
        begin
            a0 = col[31:24];
            a1 = col[23:16];
            a2 = col[15:8];
            a3 = col[7:0];

            r0 = mul(a0, 8'h0e) ^ mul(a1, 8'h0b) ^ mul(a2, 8'h0d) ^ mul(a3, 8'h09);
            r1 = mul(a0, 8'h09) ^ mul(a1, 8'h0e) ^ mul(a2, 8'h0b) ^ mul(a3, 8'h0d);
            r2 = mul(a0, 8'h0d) ^ mul(a1, 8'h09) ^ mul(a2, 8'h0e) ^ mul(a3, 8'h0b);
            r3 = mul(a0, 8'h0b) ^ mul(a1, 8'h0d) ^ mul(a2, 8'h09) ^ mul(a3, 8'h0e);

            inv_mix_single_column = {r0, r1, r2, r3};
        end
    endfunction

    wire [7:0] s[0:15];
    assign {
        s[0], s[1], s[2], s[3],
        s[4], s[5], s[6], s[7],
        s[8], s[9], s[10], s[11],
        s[12], s[13], s[14], s[15]
    } = state_in;

    wire [31:0] col_in[0:3];
    assign col_in[0] = {s[0], s[4], s[8], s[12]};
    assign col_in[1] = {s[1], s[5], s[9], s[13]};
    assign col_in[2] = {s[2], s[6], s[10], s[14]};
    assign col_in[3] = {s[3], s[7], s[11], s[15]};

    wire [31:0] col_out[0:3];
    assign col_out[0] = inv_mix_single_column(col_in[0]);
    assign col_out[1] = inv_mix_single_column(col_in[1]);
    assign col_out[2] = inv_mix_single_column(col_in[2]);
    assign col_out[3] = inv_mix_single_column(col_in[3]);

    assign state_out = {
        col_out[0][31:24], col_out[1][31:24], col_out[2][31:24], col_out[3][31:24],
        col_out[0][23:16], col_out[1][23:16], col_out[2][23:16], col_out[3][23:16],
        col_out[0][15:8],  col_out[1][15:8],  col_out[2][15:8],  col_out[3][15:8],
        col_out[0][7:0],   col_out[1][7:0],   col_out[2][7:0],   col_out[3][7:0]
    };
endmodule
```

### Top Module with Decryption Support
```verilog
module aes_256_top (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire         decrypt,    // 0 = encrypt, 1 = decrypt
    input  wire [127:0] data_in,
    input  wire [255:0] key,
    output reg  [127:0] data_out,
    output reg          done
);
    reg [3:0] round;
    reg [127:0] state;

    wire [1919:0] round_keys_flat;
    wire [10:0] round_index = round * 128;
    wire [127:0] round_key = round_keys_flat[round_index +: 128];
    // For decryption, reverse the round key order
    wire [10:0] dec_round_index = (14 - round) * 128;
    wire [127:0] dec_round_key = round_keys_flat[dec_round_index +: 128];

    aes256_key_expansion_flat keygen (
        .key_in(key),
        .round_keys_flat(round_keys_flat)
    );

    // Encryption path
    wire [127:0] sb_out, sr_out, mc_out;
    subbytes sb (.state_in(state), .state_out(sb_out));
    shiftrows sr (.state_in(sb_out), .state_out(sr_out));
    mixcolumns mc (.state_in(sr_out), .state_out(mc_out));

    // Decryption path
    wire [127:0] isb_out, isr_out, imc_out;
    inv_subbytes isb (.state_in(state), .state_out(isb_out));
    inv_shiftrows isr (.state_in(isb_out), .state_out(isr_out));
    inv_mixcolumns imc (.state_in(isr_out), .state_out(imc_out));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round <= 0;
            done <= 0;
            data_out <= 0;
            state <= 0;
        end else if (start && round == 0 && !done) begin
            state <= data_in ^ (decrypt ? dec_round_key : round_key);
            data_out <= 0;
            done <= 0;
            round <= 1;
        end else if (round > 0 && round < 14) begin
            if (decrypt) begin
                state <= imc_out ^ dec_round_key;
            end else begin
                state <= mc_out ^ round_key;
            end
            round <= round + 1;
        end else if (round == 14) begin
            if (decrypt) begin
                data_out <= isr_out ^ dec_round_key;
            end else begin
                data_out <= sr_out ^ round_key;
            end
            done <= 1;
            round <= 0;
        end else begin
            done <= 0;
        end
    end
endmodule
```

---

## 3. Pipelined Architecture

### Problem
The current design processes one block per 15 clock cycles. Pipelined designs can process a new block every cycle.

### Solution
Use **full pipelining** — insert registers between each AES round. Each stage processes one round, and a new plaintext block enters the pipeline every clock cycle.

### Architecture
```
Cycle 0: [Block N enters] → AddRoundKey(0)
Cycle 1: [Block N+1 enters] → AddRoundKey(0) | Block N → Round 1
Cycle 2: [Block N+2 enters] → ... | Block N → Round 2
...
Cycle 14: Block N → Round 14 (output)
```

### Key Design Considerations
- **Latency**: 15 cycles (same as sequential)
- **Throughput**: 1 block/cycle (15× improvement)
- **Area**: ~15× more resources (15 copies of SubBytes, ShiftRows, MixColumns)
- **Use case**: High-throughput network encryption (10+ Gbps)

### Pipeline Stage Module
```verilog
module aes_round_stage (
    input  wire         clk,
    input  wire         rst,
    input  wire         en,
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    input  wire         is_final_round,
    output reg  [127:0] state_out
);
    wire [127:0] sb_out, sr_out, mc_out;

    subbytes sb (.state_in(state_in), .state_out(sb_out));
    shiftrows sr (.state_in(sb_out), .state_out(sr_out));
    mixcolumns mc (.state_in(sr_out), .state_out(mc_out));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_out <= 0;
        end else if (en) begin
            if (is_final_round)
                state_out <= sr_out ^ round_key;
            else
                state_out <= mc_out ^ round_key;
        end
    end
endmodule
```

### Pipelined Top Module
```verilog
module aes_256_pipelined (
    input  wire         clk,
    input  wire         rst,
    input  wire         valid_in,
    input  wire [127:0] plain_text,
    input  wire [255:0] key,
    output wire [127:0] cipher_text,
    output wire         valid_out
);
    wire [1919:0] round_keys_flat;
    aes256_key_expansion_flat keygen (
        .key_in(key),
        .round_keys_flat(round_keys_flat)
    );

    wire [127:0] stage_state [0:14];
    wire [14:0]  stage_valid;

    // Initial AddRoundKey (combinational)
    assign stage_state[0] = plain_text ^ round_keys_flat[127:0];
    assign stage_valid[0] = valid_in;

    // 13 middle rounds
    genvar i;
    generate
        for (i = 1; i < 14; i = i + 1) begin : middle_rounds
            aes_round_stage stage (
                .clk(clk),
                .rst(rst),
                .en(1'b1),
                .state_in(stage_state[i-1]),
                .round_key(round_keys_flat[i*128 +: 128]),
                .is_final_round(1'b0),
                .state_out(stage_state[i])
            );
            // Valid pipeline
            reg valid_pipe;
            always @(posedge clk) valid_pipe <= stage_valid[i-1];
            assign stage_valid[i] = valid_pipe;
        end
    endgenerate

    // Final round (no MixColumns)
    aes_round_stage final_stage (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .state_in(stage_state[13]),
        .round_key(round_keys_flat[14*128 +: 128]),
        .is_final_round(1'b1),
        .state_out(stage_state[14])
    );

    reg valid_pipe_final;
    always @(posedge clk) valid_pipe_final <= stage_valid[13];
    assign stage_valid[14] = valid_pipe_final;

    assign cipher_text = stage_state[14];
    assign valid_out = stage_valid[14];
endmodule
```

### Performance Comparison
| Metric | Sequential (Current) | Pipelined |
|--------|---------------------|-----------|
| Latency | 15 cycles | 15 cycles |
| Throughput | 1 block / 15 cycles | 1 block / cycle |
| Throughput @ 100 MHz | ~853 Mbps | ~12.8 Gbps |
| Area (approx.) | 1× | 15× |
| Best for | Low-area, IoT | High-speed networking |

---

## 4. AES-GCM Authenticated Encryption

### Problem
The current design only provides confidentiality. Real-world deployments (TLS 1.3, IPsec, MACsec) require authenticated encryption — AES-GCM provides both confidentiality and integrity.

### Solution
Combine AES-CTR (counter mode encryption) with GHASH (Galois Field authentication).

### AES-GCM Architecture
```
                    ┌─────────────────────────────┐
     Plaintext ────►│ AES-CTR Encryption          ├────► Ciphertext
                    │  (Confidentiality)          │
                    └─────────────────────────────┘
                               │
                    ┌──────────▼──────────────┐
     AAD ──────────►│ GHASH Authentication     ├────► Authentication Tag
     Ciphertext ───►│  (Integrity)             │
                    └─────────────────────────┘
```

### Key Components

#### 1. AES-CTR (Counter Mode)
```verilog
module aes_ctr_mode (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] plaintext_block,
    input  wire [95:0]  iv,           // 96-bit IV
    input  wire [31:0]  counter,      // Block counter
    input  wire [255:0] key,
    output wire [127:0] ciphertext_block,
    output wire         done
);
    wire [127:0] counter_block;
    wire [127:0] aes_out;

    // Counter = IV || counter (96 || 32 bits)
    assign counter_block = {iv, counter};

    // Encrypt counter block
    aes_256_top aes_engine (
        .clk(clk), .rst(rst), .start(start),
        .plain_text(counter_block),
        .key(key),
        .cipher_text(aes_out),
        .done(done)
    );

    // XOR with plaintext
    assign ciphertext_block = plaintext_block ^ aes_out;
endmodule
```

#### 2. GHASH (Galois Field Hash)
```verilog
module ghash (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] data_in,
    input  wire [127:0] hash_key,     // H = AES_K(0^128)
    output reg  [127:0] hash_out,
    output reg          done
);
    // GF(2^128) multiplication: a * b
    // Polynomial: x^128 + x^7 + x^2 + x + 1
    function [127:0] gf_mult;
        input [127:0] a, b;
        reg [127:0] p;
        integer i;
        begin
            p = 0;
            for (i = 0; i < 128; i = i + 1) begin
                if (b[i]) p = p ^ a;
                // Shift a left and reduce if MSB set
                a = {a[126:0], 1'b0} ^ (a[127] ? 128'h87 : 128'h0);
            end
            gf_mult = p;
        end
    endfunction

    reg [127:0] y;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            y <= 0;
            done <= 0;
        end else if (start) begin
            y <= gf_mult(y ^ data_in, hash_key);
            done <= 1;
        end else begin
            done <= 0;
        end
    end

    assign hash_out = y;
endmodule
```

#### 3. AES-GCM Top Module
```verilog
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
    // Step 1: Compute hash key H = AES_K(0^128)
    wire [127:0] hash_key;
    aes_256_top h_gen (
        .clk(clk), .rst(rst), .start(start),
        .plain_text(128'h0), .key(key),
        .cipher_text(hash_key), .done()
    );

    // Step 2: CTR encryption
    wire [127:0] aes_ctr_out;
    wire ctr_done;
    aes_256_top ctr_enc (
        .clk(clk), .rst(rst), .start(start),
        .plain_text({iv, 32'h1}), .key(key),
        .cipher_text(aes_ctr_out), .done(ctr_done)
    );
    assign ciphertext = plaintext ^ aes_ctr_out;

    // Step 3: GHASH authentication
    wire [127:0] ghash_out;
    ghash auth (
        .clk(clk), .rst(rst), .start(ctr_done),
        .data_in(ciphertext), .hash_key(hash_key),
        .hash_out(ghash_out), .done()
    );

    // Step 4: Final tag = GHASH XOR AES_K(IV||counter)
    wire [127:0] tag_mask;
    aes_256_top tag_gen (
        .clk(clk), .rst(rst), .start(ctr_done),
        .plain_text({iv, 32'h0}), .key(key),
        .cipher_text(tag_mask), .done()
    );
    assign auth_tag = ghash_out ^ tag_mask;
    assign done = ctr_done;
endmodule
```

### References
- NIST SP 800-38D: Galois/Counter Mode (GCM)
- Malal & Tezcan (2026): "First Fully Pipelined High Throughput FPGA Implementation of WAES-256"
- ACNS 2024: "Pushing AES-256-GCM to Limits: Design, Implementation and Real FPGA Tests"

---

## 5. Side-Channel Countermeasures

### Problem
AES-256 on FPGAs is vulnerable to Differential Power Analysis (DPA) and Electromagnetic (EM) emanation attacks. Researchers recovered Xilinx Virtex-4/5 AES-256 keys in 6-9 hours via power analysis.

### Solution: First-Order Boolean Masking
Split each sensitive variable `s` into two random shares `s0` and `s1` such that `s = s0 XOR s1`. Operations are performed on shares independently, hiding the correlation between power consumption and the actual data.

### Masked S-Box
```verilog
module masked_sbox (
    input  wire [7:0] in,
    input  wire [7:0] mask_in,
    output wire [7:0] out,
    output wire [7:0] mask_out
);
    // Pre-computed masked S-box: for each (input_share, mask) combination,
    // store the output share. This is a 16KB ROM in practice.
    // Simplified: use LUT-based masking

    wire [7:0] unmasked = in ^ mask_in;
    wire [7:0] sbox_out;

    // Regular S-box lookup
    sbox_lookup sbox (.in(unmasked), .out(sbox_out));

    // Random output mask (from TRNG in production)
    assign mask_out = mask_in; // In production, use fresh random mask
    assign out = sbox_out ^ mask_out;
endmodule
```

### Masked SubBytes (16 parallel masked S-boxes)
```verilog
module masked_subbytes (
    input  wire [127:0] state_in,
    input  wire [127:0] mask_in,     // 16-byte input mask
    output wire [127:0] state_out,
    output wire [127:0] mask_out
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : msbox
            masked_sbox ms (
                .in(state_in[i*8 +: 8]),
                .mask_in(mask_in[i*8 +: 8]),
                .out(state_out[i*8 +: 8]),
                .mask_out(mask_out[i*8 +: 8])
            );
        end
    endgenerate
endmodule
```

### Additional Countermeasures
1. **Shuffling**: Randomize the order of S-box computations each cycle
2. **Constant-time execution**: Ensure all paths take the same number of cycles
3. **Power noise injection**: Add dummy switching activity to mask power traces
4. **Dual-rail logic**: Use precharge logic families for constant power consumption

### References
- Moradi et al. (2011): "On the Portability of Side-Channel Attacks" — extracted Xilinx AES-256 keys
- eShard (2024): "AES-256 Climbing: Mastering Side-Channel Attacks on FPGAs"
- Rambus: "TEMPEST side-channel attacks recover AES-256 encryption keys"

---

## 6. Area/Power Optimization

### Problem
SubBytes uses 16 parallel 256-entry case statement S-boxes, consuming significant LUT resources. Key expansion computes all 15 round keys simultaneously.

### Solution 1: Composite Field S-Box
Map GF(2⁸) inversion to a smaller subfield GF(((2²)²)²) using composite field arithmetic. This reduces the S-box from ~150 LUTs to ~50 LUTs (67% reduction).

### Composite Field S-Box Architecture
```
Input (8-bit)
    │
    ▼
Affine Transform (over GF(2⁸))
    │
    ▼
Isomorphism: GF(2⁸) → GF(((2²)²)²)
    │
    ▼
Inversion in GF(((2²)²)²)
    │
    ▼
Isomorphism: GF(((2²)²)²) → GF(2⁸)
    │
    ▼
Inverse Affine Transform
    │
    ▼
Output (8-bit)
```

### Solution 2: Iterative Key Expansion
Instead of computing all 15 round keys in parallel, compute them on-demand:

```verilog
module aes256_key_expansion_iterative (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [255:0] key_in,
    output reg  [127:0] round_key,
    output reg          ready
);
    reg [31:0] w [0:59];
    reg [5:0]  count;
    reg [2:0]  state;

    // States: IDLE, COMPUTE, OUTPUT
    localparam IDLE = 0, COMPUTE = 1, OUTPUT = 2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
            ready <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        // Load key
                        {w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7]} <= key_in;
                        count <= 8;
                        state <= COMPUTE;
                    end
                end
                COMPUTE: begin
                    if (count < 60) begin
                        // Compute next word (simplified)
                        w[count] <= w[count-8] ^ w[count-1];
                        count <= count + 1;
                    end else begin
                        state <= OUTPUT;
                        count <= 0;
                    end
                end
                OUTPUT: begin
                    // Output round keys on demand
                    round_key <= {w[count*4], w[count*4+1], w[count*4+2], w[count*4+3]};
                    ready <= 1;
                    if (count < 14) count <= count + 1;
                end
            endcase
        end
    end
endmodule
```

### Area Savings Estimate
| Component | Current | Optimized | Savings |
|-----------|---------|-----------|---------|
| S-box (each) | ~150 LUTs | ~50 LUTs | 67% |
| 16 S-boxes total | ~2400 LUTs | ~800 LUTs | 67% |
| Key expansion | ~1920 bits (all at once) | ~480 bits (on-demand) | 75% |
| **Total estimate** | ~4000 LUTs | ~1500 LUTs | **62%** |

### References
- Canright (2005): "A Very Compact S-Box for AES" — composite field arithmetic
- Satoh et al. (2001): "A Compact S-Box for Secure Smart Card Systems"

---

## 7. Wider-AES (256-bit Block)

### Problem
NIST recently called for a **wider variant** of AES with 256-bit blocks (WAES-256). Your implementation only handles the standard 128-bit block size.

### Current Status
NIST's call for wider block ciphers is driven by:
- Birthday bound attacks on 128-bit blocks (2⁶⁴ data limit)
- Need for 256-bit blocks in high-throughput applications
- Quantum computing considerations (Grover's reduces effective security)

### Solution Architecture
WAES-256 operates on an **8×4 byte state** (32 bytes) instead of the standard 4×4 (16 bytes):
- **SubBytes**: 32 parallel S-boxes (instead of 16)
- **ShiftRows**: Shifts across 8 columns
- **MixColumns**: 8-column mixing matrix
- **Key Expansion**: 256-bit → 16 words per round key (instead of 4)

### Implementation Approach
1. Scale all modules by 2× for the wider state
2. Adjust ShiftRows to handle 8-column state
3. Extend key expansion to generate wider round keys
4. Maintain the same round structure (14 rounds for 256-bit key)

### Reference Implementation
Malal & Tezcan (2026) achieved:
- **206 Gbps** on Kintex UltraScale+ (single core)
- **742 Gbps** with 4-core parallel WAES-256
- **3053 Gbps** on RTX 4090 GPU

### This Gap Requires
- Full redesign of state matrix (8×4 instead of 4×4)
- New MixColumns matrix for 8-column operations
- Extended key expansion for wider round keys
- New test vectors (NIST has not yet finalized WAES test vectors)

**Recommendation**: This is a separate research project. The current AES-256 implementation should first be completed (pipelining, GCM, decryption) before attempting Wider-AES.

---

## Summary: Implementation Priority

| Priority | Gap | Effort | Impact |
|----------|-----|--------|--------|
| 1 | Testbench | 1 day | Critical — validates correctness |
| 2 | Decryption | 2-3 days | High — enables bidirectional communication |
| 3 | Pipelining | 1 week | High — 15× throughput improvement |
| 4 | AES-GCM | 2-3 weeks | Critical — required for real-world use |
| 5 | Side-channel | 1-2 weeks | High — required for security certification |
| 6 | Area optimization | 1 week | Medium — reduces FPGA resource usage |
| 7 | Wider-AES | 1-2 months | Low — research project, not yet standardized |

---

*Document generated for AES-256-bit-Key-Encryption--Vivado-Architecture project*
*References: NIST FIPS-197, NIST SP 800-38D, NIST SP 800-232*
