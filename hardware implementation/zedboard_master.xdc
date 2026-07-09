# ZedBoard Master XDC Constraint File
# Target: Xilinx Zynq-7000 XC7Z020-1CLG484
# Board:  ZedBoard Zynq Evaluation and Development Kit
# Top:    aes_zed_top

# ── 100 MHz System Clock (Bank 33) ──
set_property PACKAGE_PIN Y9      [get_ports clk_100m]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100m]
create_clock -period 10.000 -name sys_clk [get_ports clk_100m]

# ── Reset Button (BTNU — Bank 34) ──
set_property PACKAGE_PIN T18     [get_ports rst_btn_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_btn_n]

# ── Start Button (BTNC — Bank 34) ──
set_property PACKAGE_PIN P16     [get_ports start_btn]
set_property IOSTANDARD LVCMOS33 [get_ports start_btn]

# ── LEDs (Bank 33) ──
set_property PACKAGE_PIN T22     [get_ports {led[7]}]
set_property PACKAGE_PIN T21     [get_ports {led[6]}]
set_property PACKAGE_PIN U22     [get_ports {led[5]}]
set_property PACKAGE_PIN U21     [get_ports {led[4]}]
set_property PACKAGE_PIN V22     [get_ports {led[3]}]
set_property PACKAGE_PIN W22     [get_ports {led[2]}]
set_property PACKAGE_PIN U19     [get_ports {led[1]}]
set_property PACKAGE_PIN U14     [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

# ── Done LED (LD7 — Bank 33) ──
set_property PACKAGE_PIN T22     [get_ports aes_done_led]
set_property IOSTANDARD LVCMOS33 [get_ports aes_done_led]

# ── Configuration ──
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]