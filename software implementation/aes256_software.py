#!/usr/bin/env python3
"""
AES-256 Software Implementation
Reference model for hardware RTL validation.
Based on NIST FIPS 197.
"""

SBOX = [
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
    0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
    0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
    0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
    0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
    0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
    0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
    0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
    0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
    0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
    0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
    0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
    0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16,
]

INV_SBOX = [0]*256
for i in range(256):
    INV_SBOX[SBOX[i]] = i

RCON = [0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,0x36,0x6c,0xd8,0xab,0x4d]

# State is stored as a 4x4 matrix in column-major order:
# state[0,0] state[0,1] state[0,2] state[0,3]     s[0]  s[4]  s[8]   s[12]
# state[1,0] state[1,1] state[1,2] state[1,3]  =  s[1]  s[5]  s[9]   s[13]
# state[2,0] state[2,1] state[2,2] state[2,3]     s[2]  s[6]  s[10]  s[14]
# state[3,0] state[3,1] state[3,2] state[3,3]     s[3]  s[7]  s[11]  s[15]

def xtime(a):
    return ((a << 1) ^ 0x1b) & 0xff if a & 0x80 else (a << 1) & 0xff

def gmul(a, b):
    p = 0
    for _ in range(8):
        if b & 1:
            p ^= a
        hi = a & 0x80
        a = (a << 1) & 0xff
        if hi:
            a ^= 0x1b
        b >>= 1
    return p

def sub_bytes(state):
    return [SBOX[b] for b in state]

def inv_sub_bytes(state):
    return [INV_SBOX[b] for b in state]

def shift_rows(state):
    s = list(state)
    # Row 1: cyclic shift left by 1
    s[1], s[5], s[9], s[13] = s[5], s[9], s[13], s[1]
    # Row 2: cyclic shift left by 2
    s[2], s[6], s[10], s[14] = s[10], s[14], s[2], s[6]
    # Row 3: cyclic shift left by 3
    s[3], s[7], s[11], s[15] = s[15], s[3], s[7], s[11]
    return s

def inv_shift_rows(state):
    s = list(state)
    s[1], s[5], s[9], s[13] = s[13], s[1], s[5], s[9]
    s[2], s[6], s[10], s[14] = s[10], s[14], s[2], s[6]
    s[3], s[7], s[11], s[15] = s[7], s[11], s[15], s[3]
    return s

def mix_columns(state):
    s = list(state)
    for c in range(4):
        i0, i1, i2, i3 = 4*c, 4*c+1, 4*c+2, 4*c+3
        a = [s[i0], s[i1], s[i2], s[i3]]
        s[i0] = xtime(a[0]) ^ (xtime(a[1]) ^ a[1]) ^ a[2] ^ a[3]
        s[i1] = a[0] ^ xtime(a[1]) ^ (xtime(a[2]) ^ a[2]) ^ a[3]
        s[i2] = a[0] ^ a[1] ^ xtime(a[2]) ^ (xtime(a[3]) ^ a[3])
        s[i3] = (xtime(a[0]) ^ a[0]) ^ a[1] ^ a[2] ^ xtime(a[3])
    return s

def inv_mix_columns(state):
    s = list(state)
    for c in range(4):
        i0, i1, i2, i3 = 4*c, 4*c+1, 4*c+2, 4*c+3
        a = [s[i0], s[i1], s[i2], s[i3]]
        s[i0] = gmul(a[0],0x0e) ^ gmul(a[1],0x0b) ^ gmul(a[2],0x0d) ^ gmul(a[3],0x09)
        s[i1] = gmul(a[0],0x09) ^ gmul(a[1],0x0e) ^ gmul(a[2],0x0b) ^ gmul(a[3],0x0d)
        s[i2] = gmul(a[0],0x0d) ^ gmul(a[1],0x09) ^ gmul(a[2],0x0e) ^ gmul(a[3],0x0b)
        s[i3] = gmul(a[0],0x0b) ^ gmul(a[1],0x0d) ^ gmul(a[2],0x09) ^ gmul(a[3],0x0e)
    return s

def add_round_key(state, round_key):
    return [s ^ k for s, k in zip(state, round_key)]

def key_expansion(key):
    nk = len(key) // 4  # 8 for AES-256
    nr = nk + 6         # 14 for AES-256
    w = []

    # First nk words from key
    for i in range(nk):
        w.append([key[4*i], key[4*i+1], key[4*i+2], key[4*i+3]])

    # Expand
    for i in range(nk, 4 * (nr + 1)):
        temp = list(w[i-1])
        if i % nk == 0:
            # RotWord + SubWord + Rcon
            temp = temp[1:] + temp[:1]  # RotWord
            temp = [SBOX[b] for b in temp]  # SubWord
            temp[0] ^= RCON[i // nk - 1]
        elif nk > 6 and i % nk == 4:
            temp = [SBOX[b] for b in temp]
        w.append([a ^ b for a, b in zip(w[i - nk], temp)])

    # Pack into round keys (each round key = 16 bytes)
    round_keys = []
    for r in range(nr + 1):
        rk = []
        for c in range(4):
            rk.extend(w[r*4 + c])
        round_keys.append(rk)
    return round_keys

class AES256:
    def __init__(self, key):
        assert len(key) == 32, "AES-256 requires a 32-byte key"
        self.round_keys = key_expansion(key)
        self.nr = 14

    def encrypt(self, plaintext):
        assert len(plaintext) == 16
        state = list(plaintext)

        state = add_round_key(state, self.round_keys[0])

        for r in range(1, self.nr):
            state = sub_bytes(state)
            state = shift_rows(state)
            state = mix_columns(state)
            state = add_round_key(state, self.round_keys[r])

        # Final round (no MixColumns)
        state = sub_bytes(state)
        state = shift_rows(state)
        state = add_round_key(state, self.round_keys[self.nr])

        return bytes(state)

    def decrypt(self, ciphertext):
        assert len(ciphertext) == 16
        state = list(ciphertext)

        state = add_round_key(state, self.round_keys[self.nr])

        for r in range(self.nr - 1, 0, -1):
            state = inv_shift_rows(state)
            state = inv_sub_bytes(state)
            state = add_round_key(state, self.round_keys[r])
            state = inv_mix_columns(state)

        state = inv_shift_rows(state)
        state = inv_sub_bytes(state)
        state = add_round_key(state, self.round_keys[0])

        return bytes(state)

def run_tests():
    print("AES-256 Software Implementation")
    print("=" * 40)

    test_vectors = [
        (
            bytes.fromhex("00112233445566778899aabbccddeeff"),
            bytes.fromhex("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"),
            bytes.fromhex("8ea2b7ca516745bfeafc49904b496089"),
        ),
        (
            bytes.fromhex("00000000000000000000000000000000"),
            bytes.fromhex("0000000000000000000000000000000000000000000000000000000000000000"),
            bytes.fromhex("dc95c078a2408989ad48a21492842087"),
        ),
        (
            bytes.fromhex("00112233445566778899aabbccddeeff"),
            bytes.fromhex("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"),
            bytes.fromhex("d9b8841702b50e9b5ed50a1494dff0e2"),
        ),
    ]

    passed = 0
    for i, (pt, key, expected_ct) in enumerate(test_vectors, 1):
        aes = AES256(key)
        ct = aes.encrypt(pt)
        dec = aes.decrypt(ct)

        status_enc = "PASS" if ct == expected_ct else "FAIL"
        status_dec = "PASS" if dec == pt else "FAIL"

        print(f"\nTest {i}:")
        print(f"  Plaintext:  {pt.hex()}")
        print(f"  Ciphertext: {ct.hex()} [{status_enc}]")
        if ct != expected_ct:
            print(f"  Expected:   {expected_ct.hex()}")
        print(f"  Decrypted:  {dec.hex()} [{status_dec}]")

        if ct == expected_ct and dec == pt:
            passed += 1

    print("\n" + "=" * 40)
    print(f"Results: {passed}/{len(test_vectors)} tests passed")
    return passed == len(test_vectors)

if __name__ == "__main__":
    success = run_tests()
    exit(0 if success else 1)
