# AES-256-bit-Key-Encryption--Vivado-Architecture
RTL architecture design of an AES-256 encryption core in Xilinx Vivado, verified up to structural logic and RTL schematic generation.


# AES-256 Hardware Architecture Design

## Project Overview
This project is an RTL-level hardware implementation of the AES-256 encryption standard designed using Xilinx Vivado. The primary objective was mapping the structural logic of the algorithm and analyzing data-path synthesis.

## Status: Synthesized RTL Architecture
* **Completed:** RTL design entry, compilation, and RTL Schematic/Diagram generation.
* **Current Boundary:** Hardware Pin Limitation Study (Detailed below).

## Tools Used
* **IDE:** Xilinx Vivado
* **Language:** [Verilog / VHDL - *Keep only the one you used*]

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
Because this project stopped at the RTL schematic layer due to physical routing limitations, the core architectural lesson is being actively applied to our next project: a **BB84 QKD Implementation on a Zynq ZedBoard**. 

To resolve the 500+ pin bottleneck, the architecture will transition from direct parallel I/O ports to a **Hardware-Software Co-Design** approach, using an internal **AXI4-Lite/Stream interface** to stream data through the Zynq Processing System (PS) instead of physical FPGA pins.



## Synthesized RTL Schematic
![RTL Schematic Layout](rtl_schematic.png)
