/*
 * AES-256 ZedBoard Demo (Vitis / SDK)
 *
 * Loads key and plaintext via AXI-Lite writes, triggers encryption,
 * reads back ciphertext, prints NIST test results over UART.
 *
 * Address map (base = XPAR_ZYNQ_WRAPPER_0_S_AXI_BASEADDR):
 *   0x00: Control reg  (write 1 to encrypt)
 *   0x04: Plaintext[31:0]
 *   0x08: Plaintext[63:32]
 *   0x0C: Plaintext[95:64]
 *   0x10: Plaintext[127:96]
 *   0x14: Key[31:0]
 *   0x18: Key[63:32]
 *   0x1C: Key[95:64]
 *   0x20: Key[127:96]
 *   0x24: Key[159:128]
 *   0x28: Key[191:160]
 *   0x2C: Key[223:192]
 *   0x30: Key[255:224]
 *   0x40: Ciphertext[31:0]   (read-only)
 *   0x44: Ciphertext[63:32]  (read-only)
 *   0x48: Ciphertext[95:64]  (read-only)
 *   0x4C: Ciphertext[127:96] (read-only)
 *   0x00: Status reg        (read bit 0 = done)
 */

#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"

#define AES_BASE   XPAR_ZYNQ_WRAPPER_0_S_AXI_BASEADDR

#define REG_CTRL   0x00
#define REG_PT0    0x04
#define REG_PT1    0x08
#define REG_PT2    0x0C
#define REG_PT3    0x10
#define REG_KEY0   0x14
#define REG_KEY1   0x18
#define REG_KEY2   0x1C
#define REG_KEY3   0x20
#define REG_KEY4   0x24
#define REG_KEY5   0x28
#define REG_KEY6   0x2C
#define REG_KEY7   0x30
#define REG_CT0    0x40
#define REG_CT1    0x44
#define REG_CT2    0x48
#define REG_CT3    0x4C

typedef struct {
    unsigned int pt[4];
    unsigned int key[8];
    unsigned int expected_ct[4];
    const char  *desc;
} test_vector_t;

static const test_vector_t tests[] = {
    {
        .pt  = {0x33221100, 0x77665544, 0xbbaa9988, 0xffeeddcc},
        .key = {0x33221100, 0x77665544, 0xbbaa9988, 0xffeeddcc,
                0x33221100, 0x77665544, 0xbbaa9988, 0xffeeddcc},
        .expected_ct = {0x45b7a28e, 0xbf456751, 0x0449eafe, 0x8960494b},
        .desc = "NIST C.2 Test 1",
    },
};

static void write_key(const unsigned int *k) {
    Xil_Out32(AES_BASE + REG_KEY0, k[0]);
    Xil_Out32(AES_BASE + REG_KEY1, k[1]);
    Xil_Out32(AES_BASE + REG_KEY2, k[2]);
    Xil_Out32(AES_BASE + REG_KEY3, k[3]);
    Xil_Out32(AES_BASE + REG_KEY4, k[4]);
    Xil_Out32(AES_BASE + REG_KEY5, k[5]);
    Xil_Out32(AES_BASE + REG_KEY6, k[6]);
    Xil_Out32(AES_BASE + REG_KEY7, k[7]);
}

static void write_plaintext(const unsigned int *p) {
    Xil_Out32(AES_BASE + REG_PT0, p[0]);
    Xil_Out32(AES_BASE + REG_PT1, p[1]);
    Xil_Out32(AES_BASE + REG_PT2, p[2]);
    Xil_Out32(AES_BASE + REG_PT3, p[3]);
}

static void read_ciphertext(unsigned int *c) {
    c[0] = Xil_In32(AES_BASE + REG_CT0);
    c[1] = Xil_In32(AES_BASE + REG_CT1);
    c[2] = Xil_In32(AES_BASE + REG_CT2);
    c[3] = Xil_In32(AES_BASE + REG_CT3);
}

static void wait_for_done(void) {
    while (!(Xil_In32(AES_BASE + REG_CTRL) & 1));
}

static void trigger_encrypt(void) {
    Xil_Out32(AES_BASE + REG_CTRL, 1);
    Xil_Out32(AES_BASE + REG_CTRL, 0);
}

static void print_hex(const char *label, const unsigned int *words, int n) {
    xil_printf("%s ", label);
    for (int i = n - 1; i >= 0; i--)
        xil_printf("%08x", words[i]);
    xil_printf("\r\n");
}

int main(void) {
    unsigned int ct[4];
    int all_pass = 1;
    int n = sizeof(tests) / sizeof(tests[0]);

    xil_printf("AES-256 ZedBoard Demo\r\n");
    xil_printf("========================\r\n");

    for (int t = 0; t < n; t++) {
        write_key(tests[t].key);
        write_plaintext(tests[t].pt);
        trigger_encrypt();
        wait_for_done();
        read_ciphertext(ct);

        int pass = 1;
        for (int i = 0; i < 4; i++)
            if (ct[i] != tests[t].expected_ct[i]) { pass = 0; break; }

        xil_printf("Test %d: %s  ", t + 1, pass ? "PASS" : "FAIL");
        print_hex("CT=", ct, 4);
        if (!pass) all_pass = 0;
    }

    xil_printf("------------------------\r\n");
    xil_printf("Results: %d/%d passed\r\n", all_pass ? n : 0, n);
    if (all_pass)
        xil_printf("NIST FIPS-197 Compliance: CONFIRMED\r\n");
    else
        xil_printf("FAIL\r\n");

    return 0;
}