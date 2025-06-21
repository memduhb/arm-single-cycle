# ARM Single-Cycle Processor (Verilog Implementation)

This project is a Verilog implementation of an **ARM single-cycle processor**, based on the architecture described in *Harris & Harris's* _Digital Design and Computer Architecture_. It was developed as part of the **EE446: Computer Organization Laboratory** course at **Middle East Technical University (METU)**.

---

## Features

This processor implements a single-cycle ARM datapath and supports the following instruction set:

### Instruction Set (ISA)

- **Arithmetic & Logic:**
  - `ADD`, `SUB`, `AND`, `ORR`, `CMP`
- **Data Movement:**
  - `MOV` (register), `MOV` (immediate)
- **Memory Access:**
  - `STR`, `LDR`
- **Control Flow:**
  - `B`, `BL`, `BX`

### Extended Instructions
Additional instructions beyond the base design:
- `CMP` (compare without storing result)
- `BX` (branch and exchange)
- `BL` (branch with link — used for subroutines)

---
![image](https://github.com/user-attachments/assets/bbeb01ac-da63-4a9d-a8eb-9e80613ef37d)


## Module Overview

Key modules implemented in Verilog include:

- `Datapath.v` – Main datapath with ALU, register file, and memory interface
- `ALU.v` – Arithmetic Logic Unit
- `Controller.v` – Generates control signals based on opcode
- `Register_file.v` – 16-register bank with read/write support
- `Memory.v` – Data memory
- `Instruction_memory.v` - Instruction memory
- `Mux*.v` – Multiplexers (2-to-1, 4-to-1, etc.)
- `shifter.v` – Logical shift left/right unit
- `MSSD.v` – seven segment display module for nexys a7 fpga board. 

---

## Testing and Simulation

The processor was tested using **Cocotb** testbenches and synthesized for functionality on **FPGA** (Nexys A7 board).

- Functional simulation with **ModelSim / Icarus Verilog**
- Inputs: switches and buttons
- Outputs: seven-segment displays for observing results

---

