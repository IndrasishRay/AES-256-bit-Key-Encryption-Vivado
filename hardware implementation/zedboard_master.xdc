# ZedBoard Master XDC Constraint File
# Target: Xilinx Zynq-7000 XC7Z020-1CLG484
# Board:  ZedBoard Zynq Evaluation and Development Kit

# This file maps the AES-256 top module ports to physical pins
# on the ZedBoard. Uncomment the lines that match your ports.

# ── Clock ──
# 100 MHz oscillator on the PL side (pin Y9)
set_property PACKAGE_PIN Y9      [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

# ── Reset (use BTNU push button) ──
# set_property PACKAGE_PIN T18     [get_ports rst]
# set_property IOSTANDARD LVCMOS33 [get_ports rst]

# ── Start signal (use SW0 DIP switch) ──
# set_property PACKAGE_PIN F22     [get_ports start]
# set_property IOSTANDARD LVCMOS33 [get_ports start]

# ── Done signal (use LD0 LED) ──
# set_property PACKAGE_PIN T22     [get_ports done]
# set_property IOSTANDARD LVCMOS33 [get_ports done]

# ── Plain Text (128-bit) ──
# Use PMOD JA or JB for input. Connect 8-bit at a time.
# Below is an example using PMOD JA (pins JA1-JA4 for nibble).
# set_property PACKAGE_PIN Y11     [get_ports {plain_text[7]}]
# set_property PACKAGE_PIN AA11    [get_ports {plain_text[6]}]
# set_property PACKAGE_PIN Y10     [get_ports {plain_text[5]}]
# set_property PACKAGE_PIN AA9     [get_ports {plain_text[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {plain_text[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {plain_text[6]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {plain_text[5]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {plain_text[4]}]

# ── Cipher Text (128-bit) ──
# Use LD0–LD7 to display 8 bits of cipher text
# set_property PACKAGE_PIN T22     [get_ports {cipher_text[7]}]
# set_property PACKAGE_PIN T21     [get_ports {cipher_text[6]}]
# set_property PACKAGE_PIN U22     [get_ports {cipher_text[5]}]
# set_property PACKAGE_PIN U21     [get_ports {cipher_text[4]}]
# set_property PACKAGE_PIN V22     [get_ports {cipher_text[3]}]
# set_property PACKAGE_PIN W22     [get_ports {cipher_text[2]}]
# set_property PACKAGE_PIN U19     [get_ports {cipher_text[1]}]
# set_property PACKAGE_PIN U14     [get_ports {cipher_text[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {cipher_text[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {cipher_text[6]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {cipher_text[5]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {cipher_text[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {cipher_text[3]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {cipher_text[2]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {cipher_text[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {cipher_text[0]}]

# ── Key (256-bit) ──
# Option A: Hard-code the key inside the Verilog testbench
# Option B: Use DIP switches SW0-SW7 for 8 bits at a time
# Option C: Use UART to load the key via the USB-UART bridge
# For simplicity, Option A is recommended for ZedBoard demos.

# ── Configuration ──
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# ── Additional hints ──
# The ZedBoard uses the Digilent SMT1-equivalent circuit for JTAG.
# The PL LED (LD0–LD7) pins are in Bank 33 (VCCO = 3.3V).
# DIP switches SW0–SW7 are in Bank 34 (VCCO = 3.3V).
# Push buttons BTNU/BTNR/BTND/BTNC/BTNL are in Bank 34 (VCCO = 3.3V).
# PMOD JA is in Bank 13 (VCCO = 3.3V).
# 100 MHz system clock is at pin Y9 (Bank 33).