# AES-256-bit-Key-Encryption--Vivado-Architecture
RTL architecture design of an AES-256 encryption core in Xilinx Vivado, verified up to structural logic and RTL schematic generation.

## Project Overview
This project is an RTL-level hardware implementation of the AES-256 encryption standard designed using Xilinx Vivado. The primary objective was mapping the structural logic of the algorithm and analyzing data-path synthesis.

## Status
* **Completed:** RTL design, compilation, RTL Schematic generation, decryption, pipelining, AES-GCM, side-channel masking, testbench.
* **Current Boundary:** Hardware Pin Limitation Study (Detailed below).

## Tools Used
* **IDE:** Xilinx Vivado
* **Language:** Verilog

## Project Structure
```
AES-256-bit-Key-Encryption--Vivado-Architecture/
├── hardware implementation/
│   ├── Core AES Modules
│   │   ├── aes_256_top.v                 # Top-level FSM — encryption only
│   │   ├── aes_256_top_enc_dec.v         # Top-level FSM — encryption + decryption
│   │   ├── aes256_key_expansion_flat.v   # Combinational key expander
│   │   ├── subbytes.v                    # SubBytes — 16 parallel S-boxes
│   │   ├── sbox_lookup.v                 # AES S-box (256-entry LUT)
│   │   ├── shiftrows.v                   # ShiftRows — byte permutation
│   │   └── mixcolumns.v                  # MixColumns — GF(2^8) mixing
│   │
│   ├── Decryption Modules
│   │   ├── inv_sbox_lookup.v             # Inverse S-box
│   │   ├── inv_subbytes.v                # Inverse SubBytes
│   │   ├── inv_shiftrows.v               # Inverse ShiftRows
│   │   └── inv_mixcolumns.v              # Inverse MixColumns
│   │
│   ├── Pipelined Architecture
│   │   ├── aes_256_pipelined.v           # 15-stage fully pipelined AES
│   │   └── aes_round_stage.v             # Single pipeline stage module
│   │
│   ├── AES-GCM (Authenticated Encryption)
│   │   ├── aes_gcm_top.v                 # AES-GCM: CTR + GHASH
│   │   └── ghash.v                       # GF(2^128) GHASH multiplier
│   │
│   ├── Side-Channel Countermeasures
│   │   ├── masked_sbox.v                 # Boolean-masked S-box
│   │   └── masked_subbytes.v             # 16 masked S-boxes
│   │
│   ├── Testbench
│   │   └── tb_aes_256_top.v              # NIST FIPS-197 test vectors
│   │
│   └── aes_256_schematic.png.png         # Synthesized RTL schematic
├── software implementation/              # (Placeholder)
├── IMPLEMENTATION_GUIDE.md               # Research gaps & solutions
└── README.md
```

## Module Hierarchy

### Core AES
| Module | File | Description |
|---|---|---|
| `aes_256_top` | `aes_256_top.v` | Top-level FSM — 14-round encryption controller |
| `aes_256_top_enc_dec` | `aes_256_top_enc_dec.v` | Top-level with encryption + decryption support |
| `aes256_key_expansion_flat` | `aes256_key_expansion_flat.v` | Combinational key expander — 15 round keys from 256-bit key |
| `subbytes` | `subbytes.v` | SubBytes — 16 parallel S-box substitutions |
| `sbox_lookup` | `sbox_lookup.v` | AES S-box (256-entry lookup table) |
| `shiftrows` | `shiftrows.v` | ShiftRows — byte permutation across state rows |
| `mixcolumns` | `mixcolumns.v` | MixColumns — GF(2^8) column mixing |

### Decryption
| Module | File | Description |
|---|---|---|
| `inv_sbox_lookup` | `inv_sbox_lookup.v` | Inverse AES S-box |
| `inv_subbytes` | `inv_subbytes.v` | Inverse SubBytes — 16 parallel inverse S-boxes |
| `inv_shiftrows` | `inv_shiftrows.v` | Inverse ShiftRows — reverse byte permutation |
| `inv_mixcolumns` | `inv_mixcolumns.v` | Inverse MixColumns — GF(2^8) inverse column mixing |

### Pipelined
| Module | File | Description |
|---|---|---|
| `aes_256_pipelined` | `aes_256_pipelined.v` | 15-stage fully pipelined AES — 1 block/cycle throughput |
| `aes_round_stage` | `aes_round_stage.v` | Single pipeline stage (SubBytes + ShiftRows + MixColumns + AddRoundKey) |

### AES-GCM
| Module | File | Description |
|---|---|---|
| `aes_gcm_top` | `aes_gcm_top.v` | AES-GCM authenticated encryption (CTR + GHASH) |
| `ghash` | `ghash.v` | GF(2^128) hash function for authentication |

### Side-Channel
| Module | File | Description |
|---|---|---|
| `masked_sbox` | `masked_sbox.v` | Boolean-masked S-box for DPA resistance |
| `masked_subbytes` | `masked_subbytes.v` | 16 masked S-boxes for first-order masking |

## Implemented Features

### Decryption
Inverse transformation modules (`inv_subbytes`, `inv_shiftrows`, `inv_mixcolumns`) enable bidirectional AES. The `aes_256_top_enc_dec` module selects encrypt/decrypt via a `decrypt` input. Decryption reverses the round key order.

### Pipelined Architecture
`aes_256_pipelined` inserts registers between each AES round. A new plaintext block enters every clock cycle. Latency remains 15 cycles, but throughput increases from 1 block/15 cycles to 1 block/cycle (~15x improvement).

### AES-GCM Authenticated Encryption
`aes_gcm_top` combines AES-CTR (confidentiality) with GHASH (integrity). Provides both encryption and authentication — required by TLS 1.3, IPsec, and MACsec (802.1AE).

### Side-Channel Masking
`masked_sbox` and `masked_subbytes` implement first-order Boolean masking. Each S-box input is split into two random shares, hiding the correlation between power consumption and secret data.

### Testbench
`tb_aes_256_top` verifies against NIST FIPS-197 AES-256 test vectors (Appendix C.3). Tests three known plaintext-key-ciphertext triples and reports pass/fail.

## Bug Fixes (v2)
1. **Pulse-triggered FSM** — `start` is now a single-cycle trigger; FSM runs autonomously.
2. **`done` auto-clear** — Pulses HIGH for one cycle, then clears.
3. **Stale `cipher_text`** — Cleared at start of each new encryption.
4. **Port mismatch** — Removed unused `clk`/`rst`/`start` from key expansion module.
5. **`state` reset** — All registers now initialized on `rst`.

## Architectural Case Study: The I/O Pin Bottleneck
During the initial synthesis phase, the design encountered an **I/O Placement Overutilization Error**.

### The Problem:
A fully parallelized AES-256 core requires:
* 256 bits for the Key input
* 128 bits for the Plaintext input
* 128 bits for the Ciphertext output
* Additional control signals (`clk`, `rst`, `ready`, etc.)

This results in a top-level module requiring **515+ physical I/O pins**. When compiled without a specific pin-reduction strategy, Vivado identifies that the design exceeds the available physical package boundaries of standard target FPGAs.

### Next Steps & Key Takeaways:
To resolve the 500+ pin bottleneck, the architecture will transition from direct parallel I/O ports to a **Hardware-Software Co-Design** approach, using an internal **AXI4-Lite/Stream interface** to stream data through the Zynq Processing System (PS) instead of physical FPGA pins.

## Synthesized RTL Schematic
![AES-256 Top-Level Schematic](hardware%20implementation/aes_256_schematic.png.png)
