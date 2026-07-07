# Hardware Implementation — AES-256 RTL Architecture

Verilog RTL implementation of the AES-256 encryption standard targeting Xilinx Vivado FPGAs.

## Overview

This directory contains the complete hardware implementation of AES-256, including:
- Core AES encryption/decryption
- Pipelined architecture for high throughput
- AES-GCM authenticated encryption
- Side-channel countermeasures (Boolean masking)
- NIST testbench verification

## Module Reference

### Core AES

| Module | File | Inputs | Outputs | Description |
|--------|------|--------|---------|-------------|
| `aes_256_top` | `aes_256_top.v` | `clk, rst, start, plain_text[127:0], key[255:0]` | `cipher_text[127:0], done` | 14-round encryption FSM |
| `aes_256_top_enc_dec` | `aes_256_top_enc_dec.v` | `clk, rst, start, decrypt, data_in[127:0], key[255:0]` | `data_out[127:0], done` | Encryption + decryption |
| `aes256_key_expansion_flat` | `aes256_key_expansion_flat.v` | `key_in[255:0]` | `round_keys_flat[1919:0]` | Generates 15 round keys |
| `subbytes` | `subbytes.v` | `state_in[127:0]` | `state_out[127:0]` | 16 parallel S-box substitutions |
| `sbox_lookup` | `sbox_lookup.v` | `in[7:0]` | `out[7:0]` | AES S-box (256-entry LUT) |
| `shiftrows` | `shiftrows.v` | `state_in[127:0]` | `state_out[127:0]` | Byte permutation across rows |
| `mixcolumns` | `mixcolumns.v` | `state_in[127:0]` | `state_out[127:0]` | GF(2^8) column mixing |

### Decryption

| Module | File | Description |
|--------|------|-------------|
| `inv_sbox_lookup` | `inv_sbox_lookup.v` | Inverse AES S-box |
| `inv_subbytes` | `inv_subbytes.v` | Inverse SubBytes — 16 parallel inverse S-boxes |
| `inv_shiftrows` | `inv_shiftrows.v` | Inverse ShiftRows — reverse byte permutation |
| `inv_mixcolumns` | `inv_mixcolumns.v` | Inverse MixColumns — GF(2^8) inverse mixing |

### Pipelined Architecture

| Module | File | Description |
|--------|------|-------------|
| `aes_256_pipelined` | `aes_256_pipelined.v` | 15-stage fully pipelined AES — 1 block/cycle |
| `aes_round_stage` | `aes_round_stage.v` | Single pipeline stage module |

### AES-GCM

| Module | File | Description |
|--------|------|-------------|
| `aes_gcm_top` | `aes_gcm_top.v` | AES-GCM: CTR encryption + GHASH authentication |
| `ghash` | `ghash.v` | GF(2^128) hash function |

### Side-Channel Countermeasures

| Module | File | Description |
|--------|------|-------------|
| `masked_sbox` | `masked_sbox.v` | Boolean-masked S-box for DPA resistance |
| `masked_subbytes` | `masked_subbytes.v` | 16 masked S-boxes |

### Testbench

| Module | File | Description |
|--------|------|-------------|
| `tb_aes_256_top` | `tb_aes_256_top.v` | NIST FIPS-197 AES-256 test vectors |

## AES Algorithm Reference

### Encryption Round Structure

```
Round 0:     AddRoundKey(state, key[0])
Rounds 1-13: SubBytes → ShiftRows → MixColumns → AddRoundKey(state, key[i])
Round 14:    SubBytes → ShiftRows → AddRoundKey(state, key[14])
```

### State Layout (Column-Major)

```
s[0]  s[4]  s[8]  s[12]     ← Row 0
s[1]  s[5]  s[9]  s[13]     ← Row 1
s[2]  s[6]  s[10] s[14]     ← Row 2
s[3]  s[7]  s[11] s[15]     ← Row 3
```

### Decryption Round Structure

```
Round 0:     AddRoundKey(state, key[14])
Rounds 1-13: InvShiftRows → InvSubBytes → AddRoundKey(state, key[i]) → InvMixColumns
Round 14:    InvShiftRows → InvSubBytes → AddRoundKey(state, key[0])
```

## Running Simulations

### Icarus Verilog (Linux/macOS/Windows)

```bash
# Compile all modules
iverilog -o tb_sim -y . tb_aes_256_top.v

# Run simulation
vvp tb_sim

# View waveforms (optional)
gtkwave tb_sim.vcd
```

### Xilinx Vivado

1. Create new project → Add all `.v` files
2. Add `tb_aes_256_top.v` as simulation source
3. Run Behavioral Simulation
4. Check Tcl Console for results

## Synthesis Targets

| Target | Device | Notes |
|--------|--------|-------|
| Xilinx Artix-7 | XC7A100T | Budget FPGA, good for sequential |
| Xilinx Kintex-7 | XC7K325T | Mid-range, supports pipelined |
| Xilinx UltraScale+ | XCKU5P | High-performance, 200+ Gbps |
| Zynq ZedBoard | XC7Z020 | SoC integration with PS |

## File Naming Convention

```
aes_256_*.v          — AES core modules
*_enc_dec.v          — Encryption + decryption variant
inv_*.v              — Inverse (decryption) modules
*_pipelined.v        — Pipelined architecture
*_gcm*.v             — AES-GCM authenticated encryption
masked_*.v           — Side-channel countermeasures
tb_*.v               — Testbenches
```
