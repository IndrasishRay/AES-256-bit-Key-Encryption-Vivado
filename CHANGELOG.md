# Changelog

All notable changes to this project are documented here.

---

## [1.0.0] — 2026-07-07

### Added
- `LIVE_DEMO_SCRIPT.md` — Step-by-step terminal walkthrough (~5 min) for live presentations
- `VIDEO_SCRIPT.md` — 9-scene narrated video script (~8 min) with shot list and b-roll suggestions
- `CHANGELOG.md` — This file

### Changed
- `README.md` — Added cross-platform simulation instructions, expected output, and troubleshooting tables to both `hardware implementation/` and `software implementation/` READMEs

---

## [0.4.0] — Earlier

### Fixed
- **MixColumns bug in `aes256_software.py`**: `mix_columns()` and `inv_mix_columns()` were extracting rows (`c, c+4, c+8, c+12`) instead of columns (`4*c, 4*c+1, 4*c+2, 4*c+3`) of the column-major state matrix. Both functions were consistently wrong, so encrypt→decrypt still worked, but NIST test vectors failed.
- **NIST test vector plaintexts corrected**: Plaintext inputs were `00010203...` instead of the NIST FIPS-197 C.2 values (`00112233...`). Updated across `aes256_software.py`, `tb_aes_256_top.v`, `IMPLEMENTATION_GUIDE.md`, and both READMEs.
- After both fixes, all 3 NIST FIPS-197 C.2 test vectors pass in both software and hardware, and `decrypt(encrypt(pt)) == pt` holds.

### Added
- `aes256_software.py` — Complete Python reference implementation with validated NIST compliance
- Interactive Python REPL usage example

---

## [0.3.0] — Earlier

### Fixed
- **Pulse-triggered FSM** in `aes_256_top.v`: FSM advanced on every clock edge while `start` was high instead of triggering on the rising edge of `start`
- **Done signal auto-clear**: `done` remained asserted indefinitely until manual reset
- **Stale output retention**: `cipher_text` held previous values when not actively encrypting
- **Port width mismatch** in `aes256_key_expansion_flat.v`: Master key and I/O port 8-bit width mismatches
- **State register reset**: Internal state registers lacked proper initialization on `rst`

### Added
- `hardware implementation/` — 18 Verilog modules: iterative encrypt, encrypt-decrypt, 15-stage pipeline, AES-GCM with GHASH, side-channel masking (Boolean masking S-box)
- `IMPLEMENTATION_GUIDE.md` — 991-line documentation covering all 7 research gaps with Verilog solutions
- `software implementation/` — Python reference model and README
- `README.md` — Full project README with abstract, author credits, quick-start guide, and architecture overview

---

## [0.2.0] — Earlier

### Removed
- BB84 QKD simulation modules (Alice, Eve, Bob) — out of scope for AES project

---

## [0.1.0] — Earlier

### Added
- Initial Verilog source files for AES-256 encryption
- Basic testbench
