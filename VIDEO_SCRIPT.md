# Video Script — AES-256 Hardware-Software Co-Design

> **Duration:** ~8 minutes
> **Format:** Screen recording + voiceover
> **Tone:** Technical but accessible

---

## Scene 1: Opening (0:00–0:30)

**Visual:** Split screen — terminal on left, project logo/title on right

**VO:** *"The Advanced Encryption Standard with 256-bit keys is the backbone of modern cryptography — used everywhere from TLS to disk encryption to military communications. But building it in hardware is harder than it looks. I/O bottlenecks, side-channel vulnerabilities, and the need for authenticated encryption all complicate the design. This project implements a complete AES-256 hardware-software co-design, verified against NIST FIPS-197, targeting Xilinx Vivado FPGAs."*

---

## Scene 2: Repository Tour (0:30–1:00)

**Visual:** Terminal window, listing the repo

**VO:** *"Here's the repository. Two main directories: `hardware implementation` with 18 Verilog modules, and `software implementation` with a Python reference model. Plus a 991-line implementation guide covering 7 research gaps."*

```
Commands shown:
ls
cd AES-256-bit-Key-Encryption-Vivado
ls -R
```

**VO:** *"Let me show you both in action, starting with the software."*

---

## Scene 3: Software Demo (1:00–2:30)

**Visual:** Terminal, `cd software implementation`, run the script

**VO:** *"Pure Python, no dependencies. It implements the full AES-256 algorithm — key expansion, SubBytes, ShiftRows, MixColumns, all 14 rounds."*

```
Commands shown:
cd "software implementation"
python3 aes256_software.py
```

**VO:** *"All three NIST FIPS-197 test vectors pass. The ciphertexts match the standard exactly. Encryption and decryption are verified."

**Visual:** Focus on the PASS output, then switch to interactive Python

```
Commands shown:
python3
>>> from aes256_software import AES256
>>> aes = AES256(bytes.fromhex("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"))
>>> ct = aes.encrypt(bytes.fromhex("00112233445566778899aabbccddeeff"))
>>> ct.hex()
'8ea2b7ca516745bfeafc49904b496089'
>>> aes.decrypt(ct).hex()
'00112233445566778899aabbccddeeff'
```

**VO:** *"Encrypt returns the exact NIST ciphertext. Decrypt recovers the original plaintext. The software is a correct AES-256 implementation."*

---

## Scene 4: The Bug That Would've Gone Unnoticed (2:30–3:30)

**Visual:** Code comparison — old vs new MixColumns

**VO:** *"Here's something you won't see in textbooks. The original MixColumns function used row indices instead of column indices — `state[c], state[c+4], state[c+8], state[c+12]`. But the column-major AES state stores columns as `4c, 4c+1, 4c+2, 4c+3`."*

**Visual:** Animate the state matrix with arrows showing the difference

**VO:** *"This meant MixColumns was mixing the wrong bytes. Surprisingly, encrypt and decrypt were still inverses of each other — because both used the same wrong indexing. Only the NIST test vectors caught it. This is why standard test vectors are non-negotiable in crypto engineering."*

**Visual:** Show the fix

```
Changed from:
    i0, i1, i2, i3 = c, c+4, c+8, c+12
To:
    i0, i1, i2, i3 = 4*c, 4*c+1, 4*c+2, 4*c+3
```

**VO:** *"One change, and all three tests pass. The hardware had the same bug and the same fix."*

---

## Scene 5: Hardware Simulation (3:30–5:00)

**Visual:** Switch to `cd "../hardware implementation"`

**VO:** *"Now the hardware. 18 Verilog modules implementing everything you need for real-world AES deployment."*

```
Commands shown:
cd "../hardware implementation"
ls *.v
```

**VO:** *"Let me highlight the four key architectures."*

**Visual:** Show each file briefly

**VO:** *"`aes_256_top` — iterative encryption, 14-round FSM. `aes_256_top_enc_dec` — adds decryption. `aes_256_pipelined` — 15-stage pipeline for high throughput. `aes_gcm_top` — authenticated encryption with GHASH."*

**Visual:** Compile and simulate

```
Commands:
iverilog -o tb_sim -y . tb_aes_256_top.v
vvp tb_sim
```

**VO:** *"Same test vectors, same ciphertexts. Hardware matches software exactly. This is proper cross-validation."*

**Visual:** Zoom in on the PASS output

---

## Scene 6: Module Deep Dive — aes_256_top (5:00–6:00)

**Visual:** Show the module hierarchy or schematic

```verilog
module aes_256_top(
    input  wire         clk, rst, start,
    input  wire [127:0] plain_text,
    input  wire [255:0] key,
    output reg  [127:0] cipher_text,
    output reg          done
);
```

**VO:** *"The top module has a clean interface — clock, reset, start, 128-bit plaintext, 256-bit key. Output is 128-bit ciphertext with a done signal."*

**Visual:** Animate the FSM flow

```
State Machine:
  IDLE → AddRoundKey → SubBytes → ShiftRows → MixColumns → ...
  ... → Final Round (no MixColumns) → DONE
```

**VO:** *"Inside, it's a state machine that cycles through 14 rounds, reusing the same SubBytes, ShiftRows, and MixColumns logic each cycle. That saves hardware at the cost of 15-cycle latency."*

**Visual:** Show the pipelined architecture

**VO:** *"For high-throughput applications, the pipelined variant instantiates 15 separate round stages. Once the pipeline fills, it produces one encrypted block every clock cycle — about 12.8 gigabits per second at 100 megahertz."*

---

## Scene 7: AES-GCM — Real-World Ready (6:00–6:45)

**Visual:** Show aes_gcm_top.v and ghash.v

**VO:** *"CTR mode alone isn't enough for production use — you need authentication to detect tampering. AES-GCM combines CTR encryption with a GHASH authenticator."*

**Visual:** Animate the GCM flow

```
Encrypt:
  IV||1 → AES → keystream → XOR plaintext → ciphertext
Authenticate:
  AAD || ciphertext → GHASH(H, ...) → XOR AES(IV||0) → tag
```

**VO:** *"The GCM top module instantiates three AES cores plus a GHASH multiplier. It generates a ciphertext and an authentication tag. Any tampering invalidates the tag."*

---

## Scene 8: Side-Channel Countermeasures (6:45–7:15)

**Visual:** Show masked_sbox.v

**VO:** *"Real AES chips face physical attacks. Differential Power Analysis measures power consumption to recover the key. The countermeasure is Boolean masking — XOR a random mask before the S-box lookup, then XOR it out after."*

```verilog
module masked_sbox (
    input  wire [7:0] in,
    input  wire [7:0] mask_in,
    output wire [7:0] out,
    output wire [7:0] mask_out
);
    wire [7:0] unmasked = in ^ mask_in;
    wire [7:0] sbox_out;
    sbox_lookup sbox (.in(unmasked), .out(sbox_out));
    assign mask_out = mask_in;
    assign out = sbox_out ^ mask_out;
endmodule
```

**VO:** *"The intermediate value between the mask XOR and the S-box is never directly observable on the power trace, making DPA significantly harder."*

---

## Scene 9: Closing (7:15–8:00)

**Visual:** Show the IMPLEMENTATION_GUIDE.md TOC

**VO:** *"The project also includes a comprehensive implementation guide covering 7 research gaps — testbench, decryption, pipelining, GCM, side-channel masking, and area optimization."*

**Visual:** Scroll up to the GitHub URL

**VO:** *"The full source is on GitHub. Clone it, run the software, simulate the hardware. Everything works on Linux, macOS, and Windows."*

**Visual:** Fade to title card with QR code

**VO:** *"AES-256 Hardware-Software Co-Design. By Indrasish Ray and Subhojit Roy. Thanks for watching."*

---

## Appendix: Shot List

| Scene | Screen Content | Duration | Notes |
|-------|---------------|----------|-------|
| 1 | Split: terminal + logo | 30s | Clean intro, no typing |
| 2 | `ls -R` output | 30s | Slow, deliberate typing |
| 3 | Python script output | 90s | Highlight PASS in green |
| 4 | Code diff animation | 60s | Animate state matrix |
| 5 | iverilog + vvp output | 90s | Show compilation speed |
| 6 | Module schematic | 60s | Animate FSM flow |
| 7 | GCM architecture | 45s | Animate data flow |
| 8 | masked_sbox code | 30s | Highlight mask paths |
| 9 | GitHub URL | 45s | End card with QR |

## Appendix: B-Roll Suggestions

- Synthesized schematic in Vivado
- Waveform viewer (gtkwave) showing clock, state, done
- `IMPLEMENTATION_GUIDE.md` scrolling through research gaps
- The I/O overutilization error from initial synthesis
