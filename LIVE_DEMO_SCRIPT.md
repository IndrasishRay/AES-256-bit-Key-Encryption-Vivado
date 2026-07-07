# Live Demo Script — AES-256 Hardware-Software Co-Design

> Run this in a terminal in front of an audience.
> Estimated time: 5-7 minutes.
> Commands are in code blocks — paste and execute as you narrate.

---

## Part 1: Setup (30 sec)

Narrator: *"Let me show you the project. First, clone the repo and `cd` in."*

```bash
git clone https://github.com/IndrasishRay/AES-256-bit-Key-Encryption-Vivado.git
cd AES-256-bit-Key-Encryption-Vivado
```

```bash
ls
```

Expected output:
```
README.md  IMPLEMENTATION_GUIDE.md  hardware implementation/  software implementation/
```

Narrator: *"Two directories — hardware (Verilog RTL) and software (Python reference model)."*

---

## Part 2: Software Demo (2 min)

Narrator: *"Let's run the software implementation first. Pure Python, zero dependencies."*

```bash
cd "software implementation"
python3 aes256_software.py
```

Expected output:
```
AES-256 Software Implementation
========================================

Test 1:
  Plaintext:  00112233445566778899aabbccddeeff
  Ciphertext: 8ea2b7ca516745bfeafc49904b496089 [PASS]
  Decrypted:  00112233445566778899aabbccddeeff [PASS]

Test 2:
  Plaintext:  00000000000000000000000000000000
  Ciphertext: dc95c078a2408989ad48a21492842087 [PASS]
  Decrypted:  00000000000000000000000000000000 [PASS]

Test 3:
  Plaintext:  00112233445566778899aabbccddeeff
  Ciphertext: d9b8841702b50e9b5ed50a1494dff0e2 [PASS]
  Decrypted:  00112233445566778899aabbccddeeff [PASS]

========================================
Results: 3/3 tests passed
```

Narrator: *"All three NIST FIPS-197 test vectors pass. Encryption and decryption are verified."*

*Optional — show interactive use:*

```python
python3
>>> from aes256_software import AES256
>>> aes = AES256(bytes.fromhex("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"))
>>> ct = aes.encrypt(bytes.fromhex("00112233445566778899aabbccddeeff"))
>>> ct.hex()
'8ea2b7ca516745bfeafc49904b496089'
>>> aes.decrypt(ct).hex()
'00112233445566778899aabbccddeeff'
>>> exit()
```

Narrator: *"Encrypt returns the expected NIST ciphertext. Decrypt recovers the original. The software is correct."*

---

## Part 3: Hardware Simulation (2 min)

Narrator: *"Now the hardware. Same algorithm, same test vectors, in Verilog."*

```bash
cd "../hardware implementation"
ls *.v
```

Expected:
```
...all 18 Verilog files...
```

Narrator: *"18 Verilog modules. Let's compile and simulate using Icarus Verilog."*

```bash
iverilog -o tb_sim -y . tb_aes_256_top.v
```

Narrator: *"Compiled clean — no errors. Now run the simulation."*

```bash
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

Narrator: *"Same NIST ciphertexts as the software. Hardware and software cross-validate perfectly."*

---

## Part 4: Architecture Overview (1 min)

Narrator: *"Let me show you what's inside."*

```bash
cat ../README.md | head -30
```

Narrator: *"The top-level has four architectures:*
- *Iterative encryption — shares one datapath across 14 rounds*
- *Encryption + decryption — bidirectional FSM*
- *15-stage pipeline — one block per clock cycle*
- *AES-GCM — authenticated encryption for real-world use*"

```bash
cat tb_aes_256_top.v
```

Narrator: *"The testbench drives the DUT with NIST test vectors and compares output. 3 test cases, 100% pass rate."*

---

## Part 5: The Bug Story (30 sec)

Narrator: *"Here's something interesting. The original MixColumns implementation extracted rows instead of columns — a subtle bug. It still passed encrypt→decrypt→encrypt because both functions were consistently wrong. Only the NIST vectors caught it."*

*Show the fix:*

```bash
grep -n "i0, i1, i2, i3" ../software\ implementation/aes256_software.py | head -4
```

Narrator: *"Changed from `c, c+4, c+8, c+12` to `4*c, 4*c+1, 4*c+2, 4*c+3`. That one fix made all three tests pass. This is exactly why NIST test vectors are non-negotiable in crypto engineering."*

---

## Part 6: Wrapping Up (30 sec)

```bash
cd ..
echo "Repository: https://github.com/IndrasishRay/AES-256-bit-Key-Encryption-Vivado"
```

Narrator: *"Full source, implementation guide with 7 research gaps, and cross-platform simulation instructions are on GitHub. Questions?"*

---

## Cheat Sheet — What to Say If Something Goes Wrong

| Problem | Recovery Line |
|---------|--------------|
| `git clone` fails | "Network issue. I have the repo cloned locally — let me switch to that." |
| `python3` not found | "Let me try `python` instead." (Windows) |
| `iverilog` not installed | "Icarus Verilog is optional — I can show the Vivado flow instead." |
| Test fails | "That's actually interesting — let me show you how we debug this." |
| Audience asks about GCM | "GCM combines CTR mode encryption with a GHASH authenticator for integrity." |
| Audience asks about pipelining | "15 stages → 15× throughput at the cost of 15× LUTs." |
