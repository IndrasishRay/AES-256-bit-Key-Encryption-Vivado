# AES-256-bit-Key-Encryption--Vivado-Architecture

RTL architecture design of an AES-256 encryption core in Xilinx Vivado, verified up to structural logic and RTL schematic generation.

## Abstract

This project presents a complete hardware-software co-design framework for the Advanced Encryption Standard (AES) with 256-bit key length. The hardware implementation provides a fully pipelined RTL architecture in Verilog targeting Xilinx Vivado FPGAs, featuring encryption/decryption, AES-GCM authenticated encryption, and side-channel countermeasures. The software implementation provides a reference Python model for algorithmic validation and educational use. The project addresses key challenges in cryptographic hardware design including I/O pin bottlenecks, side-channel vulnerability, and authenticated encryption requirements.

## Authors

| Name | Role |
|------|------|
| Indrasish Ray | Hardware Architecture, RTL Design |
| Subhojit Roy | Algorithm Design, Verification |

## Project Structure

```
AES-256-bit-Key-Encryption--Vivado-Architecture/
├── hardware implementation/    # Verilog RTL — FPGA implementation
├── software implementation/    # Python reference model
├── IMPLEMENTATION_GUIDE.md     # Research gaps & solutions
└── README.md                   # This file
```

## Quick Start

**New to this project?** See the [Beginner's Manual](#beginners-manual) below or jump to:
- [Hardware Implementation](hardware%20implementation/README.md) — Verilog modules, FPGA synthesis
- [Software Implementation](software%20implementation/README.md) — Python reference model

## Features

| Feature | Hardware | Software |
|---------|----------|----------|
| AES-256 Encryption | ✅ Verilog RTL | ✅ Python |
| AES-256 Decryption | ✅ Verilog RTL | ✅ Python |
| Pipelined Architecture | ✅ 15-stage pipeline | — |
| AES-GCM (Authenticated Encryption) | ✅ CTR + GHASH | — |
| Side-Channel Masking | ✅ Boolean masking | — |
| Testbench / Unit Tests | ✅ NIST FIPS-197 vectors | ✅ pytest |
| Synthesis Report | ✅ Vivado | — |

## Tools & Requirements

### Hardware
- **IDE:** Xilinx Vivado 2020.2+
- **Language:** Verilog (IEEE 1364-2005)
- **Target:** Any Xilinx 7-series or UltraScale+ FPGA
- **Optional:** Icarus Verilog (for simulation without Vivado)

### Software
- **Language:** Python 3.8+
- **Dependencies:** None (standard library only)

## Performance Summary

| Metric | Sequential | Pipelined |
|--------|-----------|-----------|
| Latency | 15 cycles | 15 cycles |
| Throughput @ 100 MHz | ~853 Mbps | ~12.8 Gbps |
| Area (estimated) | ~4000 LUTs | ~60000 LUTs |

## Architectural Case Study: The I/O Pin Bottleneck

During the initial synthesis phase, the design encountered an **I/O Placement Overutilization Error**. A fully parallelized AES-256 core requires 515+ physical I/O pins (256 key + 128 plaintext + 128 ciphertext + control signals), exceeding standard FPGA package limits.

**Resolution:** The architecture transitions from direct parallel I/O to a **Hardware-Software Co-Design** approach using AXI4-Lite/Stream interfaces for Zynq SoC integration.

## References

1. NIST FIPS 197 — Advanced Encryption Standard (AES)
2. NIST SP 800-38D — Galois/Counter Mode (GCM)
3. NIST SP 800-232 — Ascon-Based Lightweight Cryptography Standards
4. Moradi et al. (2011) — "On the Portability of Side-Channel Attacks"
5. Malal & Tezcan (2026) — "First Fully Pipelined High Throughput FPGA Implementation of WAES-256"

## License

This project is for educational and research purposes.

---

## Beginner's Manual

This section explains how to run this project on your own system.

### Prerequisites

| OS | What to Install |
|----|----------------|
| **Linux** (Ubuntu/Debian) | Python 3, Icarus Verilog (optional) |
| **Windows** | Python 3, Icarus Verilog or Vivado (optional) |
| **macOS** | Python 3, Icarus Verilog (optional) |

### Step 1: Clone the Repository

Open a terminal and run:

```bash
git clone https://github.com/IndrasishRay/AES-256-bit-Key-Encryption-Vivado.git
cd AES-256-bit-Key-Encryption-Vivado
```

### Step 2: Run the Software Implementation (No special tools needed)

```bash
cd "software implementation"
python3 aes256_software.py
```

You should see:
```
AES-256 Software Implementation
================================
Test 1: PASS
Test 2: PASS
Test 3: PASS
All tests passed.
```

### Step 3: Simulate the Hardware (Optional)

#### Option A: Using Icarus Verilog (Free, works on all OS)

**Install Icarus Verilog:**

| OS | Command |
|----|---------|
| Linux | `sudo apt install iverilog` |
| Windows | Download from [https://iverilog.icarus.com](https://iverilog.icarus.com) |
| macOS | `brew install icarus-verilog` |

**Run simulation:**
```bash
cd "hardware implementation"
iverilog -o tb_sim -y . tb_aes_256_top.v
vvp tb_sim
```

Expected output:
```
TEST 1: PASS  CT=8ea2b7ca516745bfeafc49904b496089
TEST 2: PASS  CT=dc95c078a2408989ad48a21492842087
TEST 3: PASS  CT=d9b8841702b50e9b5ed50a1494dff0e2
-------------------
Results: 3 passed, 0 failed
-------------------
```

#### Option B: Using Xilinx Vivado (Free WebPACK edition)

1. Open Vivado → Create Project
2. Add all `.v` files from `hardware implementation/`
3. Add `tb_aes_256_top.v` as simulation source
4. Run Behavioral Simulation
5. Check Tcl Console for PASS/FAIL results

### Step 4: View the RTL Schematic (Vivado only)

1. Open Vivado → Open Project
2. Run Synthesis → Open Synthesized Design
3. Click "Schematic" to view the RTL block diagram
4. Screenshot saved as `aes_256_schematic.png.png`

### Troubleshooting

| Problem | Solution |
|---------|----------|
| `iverilog: command not found` | Install Icarus Verilog (see Step 3) |
| `python3: command not found` | Install Python 3 from [python.org](https://python.org) |
| Vivado won't open `.v` files | Create a new project first, then add sources |
| Simulation shows all `X` | Check that all testbench signals are initialized |
| `Permission denied` on Linux | Run `chmod +x` or use `python3` instead of `./` |
