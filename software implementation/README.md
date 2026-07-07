# Software Implementation — AES-256 Reference Model

Python reference implementation of AES-256 for algorithmic validation and educational use.

## Overview

This directory contains a pure Python implementation of AES-256 with no external dependencies. It serves as:
- **Reference model** for validating hardware RTL output
- **Educational tool** for understanding the AES algorithm step-by-step
- **Test vector generator** for hardware testbench verification

## Quick Start

```bash
cd "software implementation"
python3 aes256_software.py
```

## Files

| File | Description |
|------|-------------|
| `aes256_software.py` | Complete AES-256 encrypt/decrypt implementation |
| `README.md` | This file |

## Usage

### As a Script

```bash
python3 aes256_software.py
```

Runs NIST FIPS-197 test vectors and prints results.

### As a Module

```python
from aes256_software import AES256

# Create AES-256 instance with 256-bit key
key = bytes.fromhex("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
aes = AES256(key)

# Encrypt a 128-bit block
plaintext = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
ciphertext = aes.encrypt(plaintext)
print(f"Ciphertext: {ciphertext.hex()}")

# Decrypt
decrypted = aes.decrypt(ciphertext)
print(f"Decrypted:  {decrypted.hex()}")
assert decrypted == plaintext
```

## Algorithm Implementation

### S-Box
The Substitution Box (S-Box) is implemented as a 256-entry lookup table. It provides non-linearity in the encryption process.

### Key Expansion
The AES-256 key expansion generates 15 round keys (1920 bits total) from the 256-bit input key using:
- `RotWord`: Circular byte rotation
- `SubWord`: S-box substitution on each byte
- `Rcon`: Round constant XOR

### Round Operations
Each of the 14 rounds applies:
1. **SubBytes** — Non-linear byte substitution via S-box
2. **ShiftRows** — Cyclic shift of each row
3. **MixColumns** — Matrix multiplication in GF(2^8)
4. **AddRoundKey** — XOR state with round key

## NIST Test Vectors

The implementation is verified against NIST FIPS-197 Appendix C.3:

| # | Plaintext | Key | Expected Ciphertext |
|---|-----------|-----|---------------------|
| 1 | `00112233445566778899aabbccddeeff` | `00010203...1c1d1e1f` | `8ea2b7ca516745bfeafc49904b496089` |
| 2 | `00000000000000000000000000000000` | `00000000...00000000` | `dc95c078a2408989ad48a21492842087` |
| 3 | `00112233445566778899aabbccddeeff` | `ffffffff...ffffffff` | `d9b8841702b50e9b5ed50a1494dff0e2` |

## Cross-Validation with Hardware

To compare software output with hardware RTL:

```python
from aes256_software import AES256

# Test vector from tb_aes_256_top.v
key = bytes.fromhex("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
pt = bytes.fromhex("00112233445566778899aabbccddeeff")
expected_ct = bytes.fromhex("8ea2b7ca516745bfeafc49904b496089")

aes = AES256(key)
ct = aes.encrypt(pt)
assert ct == expected_ct, f"Mismatch: {ct.hex()} != {expected_ct.hex()}"
print("Hardware-software cross-validation: PASS")
```

## Requirements

- Python 3.8+
- No external dependencies (standard library only)

---

## Demo / Walkthrough

### Step 1: Open a Terminal

| OS | How to Open |
|----|-------------|
| **Linux** | `Ctrl+Alt+T` or search "Terminal" |
| **macOS** | `Cmd+Space` → type "Terminal" → press Enter |
| **Windows** | `Win+R` → type `cmd` → press Enter, or install [Windows Terminal](https://apps.microsoft.com/detail/9n0dx20hk701) |

### Step 2: Navigate to the Project

```bash
cd "software implementation"
```

### Step 3: Run the Demo

```bash
python3 aes256_software.py
```

If `python3` is not found, try `python` instead:

| OS | Try This |
|----|----------|
| Linux | `python3 aes256_software.py` |
| macOS | `python3 aes256_software.py` |
| Windows | `python aes256_software.py` |

### Step 4: Expected Output

```
AES-256 Software Implementation
========================================
Test 1: PASS
Test 2: PASS
Test 3: PASS
========================================
Results: 3/3 tests passed
```

### Step 5: Use as an Interactive Module

```python
python3
>>> from aes256_software import AES256
>>> key = bytes.fromhex("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
>>> aes = AES256(key)
>>> ct = aes.encrypt(bytes.fromhex("00112233445566778899aabbccddeeff"))
>>> ct.hex()
'8ea2b7ca516745bfeafc49904b496089'
>>> aes.decrypt(ct).hex()
'00112233445566778899aabbccddeeff'
```

### Troubleshooting

| Problem | Solution |
|---------|----------|
| `python3: command not found` (Windows) | Use `python` instead of `python3`, or install from [python.org](https://python.org) |
| `python3: command not found` (Linux/macOS) | `sudo apt install python3` (Debian/Ubuntu), `brew install python3` (macOS) |
| `pip3: command not found` | Not needed — no external dependencies |
| `ModuleNotFoundError` | Run from the project root so `aes256_software.py` is in the current directory |
