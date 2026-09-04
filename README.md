# 8-bit Custom CPU with Custom ISA

A fully custom **8-bit CPU designed and implemented in Verilog**, featuring a custom Instruction Set Architecture (ISA), custom instruction encoding, register file, ALU, control unit, instruction ROM, processor status flag, assembler, testbench, and GTKWave-based verification.

The project was built from scratch to understand how a processor works at the RTL level — from defining an ISA and converting assembly instructions into machine code to decoding and executing those instructions in hardware.

---

## Features

- 8-bit datapath
- 16-bit instruction width
- Custom 4-bit opcode ISA
- 14 general-purpose 8-bit registers (`R0`–`R13`)
- Custom ALU
- Arithmetic operations
- Logical operations
- Register-to-register data movement
- Immediate data loading
- Processor status/carry flag
- Instruction ROM
- Hardwired combinational control unit
- Custom Python assembler
- Verilog simulation testbench
- VCD waveform generation
- GTKWave debugging and verification

---

# Architecture

The CPU consists of the following major blocks:

```text
                         +----------------------+
                         |   Program Counter    |
                         |       8-bit          |
                         +----------+-----------+
                                    |
                                    v
                         +----------------------+
                         |   Instruction ROM    |
                         |     256 x 16-bit     |
                         +----------+-----------+
                                    |
                              16-bit Instruction
                                    |
                                    v
                         +----------------------+
                         |    Control Unit      |
                         | Instruction Decoder  |
                         +----+------------+----+
                              |            |
                       Control Signals      |
                              |            |
                              v            v
                    +----------------------------+
                    |       Register File        |
                    |       14 x 8-bit           |
                    |                            |
                    |  2 Read Ports / 1 Write   |
                    +---------+--------+----------+
                              |        |
                             r_d1     r_d2
                              |        |
                              +---+----+
                                  |
                                  v
                         +----------------------+
                         |         ALU          |
                         |       8-bit          |
                         +----------+-----------+
                                    |
                              ALU Result
                                    |
                         +----------+-----------+
                         |                      |
                         v                      v
                  Register Writeback      Status Flag
                         |                      |
                         +----------+-----------+
                                    |
                                    v
                              Output Register
                                    |
                                    v
                              CPU Output Port
```

---

# Instruction Format

Every instruction is **16 bits wide**.

The general instruction format is:

```text
 15          12 11           8 7            4 3            0
+--------------+--------------+--------------+--------------+
|    OPCODE    |      R1      |      R2      |      R3      |
+--------------+--------------+--------------+--------------+
     4 bits          4 bits          4 bits          4 bits
```

The fields are:

| Field | Bits | Description |
|---|---:|---|
| Opcode | `[15:12]` | Identifies the instruction |
| R1 | `[11:8]` | Register field 1 |
| R2 | `[7:4]` | Register field 2 |
| R3 | `[3:0]` | Register field 3 |

For `LDB`, the lower 8 bits are instead interpreted as an immediate value:

```text
 15          12 11           8 7                            0
+--------------+--------------+------------------------------+
|    OPCODE    |   RDEST      |       IMMEDIATE DATA         |
+--------------+--------------+------------------------------+
```

---

# Custom ISA

The processor implements the following instructions.

| Instruction | Opcode | Category | Description |
|---|---|---|---|
| `MVR` | `0000` | Data Movement | Move register to register |
| `LDB` | `0001` | Data Movement | Load immediate byte into register |
| `STB` | `0010` | Output | Send register value to output |
| `RDS` | `0011` | Status | Send processor status to output |
| `NOT` | `1000` | Logical | Bitwise NOT |
| `AND` | `1001` | Logical | Bitwise AND |
| `ORA` | `1010` | Logical | Bitwise OR |
| `ADD` | `1011` | Arithmetic | Addition |
| `SUB` | `1100` | Arithmetic | Subtraction |
| `XOR` | `1101` | Logical | Bitwise XOR |
| `INC` | `1110` | Arithmetic | Increment |

The following opcodes are currently unused/reserved:

```text
0100
0101
0110
0111
1111
```

---

# ISA Details

## 1. MVR — Move Register

### Opcode

```text
0000
```

### Assembly Syntax

```text
MVR Rsrc, Rdest
```

### Operation

```text
Rdest ← Rsrc
```

### Encoding

```text
+--------+--------+--------+--------+
|   0    |  Rsrc  | Rdest  |   0    |
+--------+--------+--------+--------+
```

### Example

```text
MVR R1, R4
```

Result:

```text
R4 ← R1
```

The final field is unused and is set to `0`.

---

# 2. LDB — Load Byte

### Opcode

```text
0001
```

### Assembly Syntax

```text
LDB Rdest, immediate
```

### Operation

```text
Rdest ← immediate
```

### Encoding

```text
+--------+--------+------------------+
|   1    | Rdest  |   Immediate      |
+--------+--------+------------------+
  4 bits   4 bits      8 bits
```

### Example

```text
LDB R1, 0x42
```

Machine code:

```text
1142
```

Result:

```text
R1 = 0x42
```

---

# 3. STB — Store Byte to Output

### Opcode

```text
0010
```

### Assembly Syntax

```text
STB Rsrc
```

### Operation

```text
OUT ← Rsrc
```

### Encoding

```text
+--------+--------+--------+--------+
|   2    |  Rsrc  |   0    |   0    |
+--------+--------+--------+--------+
```

### Example

```text
STB R4
```

Machine code:

```text
2400
```

If:

```text
R4 = 0x5A
```

then:

```text
OUT = 0x5A
```

---

# 4. RDS — Read Processor Status

### Opcode

```text
0011
```

### Assembly Syntax

```text
RDS
```

### Operation

```text
OUT ← Processor_Status
```

The processor status is a single bit and is presented as an 8-bit output:

```text
Status = 0 → OUT = 0x00
Status = 1 → OUT = 0x01
```

### Encoding

```text
3000
```

---

# 5. NOT — Bitwise NOT

### Opcode

```text
1000
```

### Assembly Syntax

```text
NOT Rsrc, Rdest
```

### Operation

```text
Rdest ← ~Rsrc
```

### Example

```text
R1 = 0x55

NOT R1, R5
```

Result:

```text
R5 = 0xAA
```

### Encoding

```text
+--------+--------+--------+--------+
|   8    |  Rsrc  | Rdest  |   0    |
+--------+--------+--------+--------+
```

---

# 6. AND — Bitwise AND

### Opcode

```text
1001
```

### Assembly Syntax

```text
AND Rdest, Rsrc1, Rsrc2
```

### Operation

```text
Rdest ← Rsrc1 & Rsrc2
```

### Example

```text
R2 = 0x55
R7 = 0xAA

AND R1, R2, R7
```

Result:

```text
R1 = 0x00
```

### Encoding

```text
+--------+--------+--------+--------+
|   9    | Rdest  | Rsrc1  | Rsrc2  |
+--------+--------+--------+--------+
```

---

# 7. ORA — Bitwise OR

### Opcode

```text
1010
```

### Assembly Syntax

```text
ORA Rdest, Rsrc1, Rsrc2
```

### Operation

```text
Rdest ← Rsrc1 | Rsrc2
```

### Example

```text
R2 = 0x55
R8 = 0xAA

ORA R1, R2, R8
```

Result:

```text
R1 = 0xFF
```

### Encoding

```text
+--------+--------+--------+--------+
|   A    | Rdest  | Rsrc1  | Rsrc2  |
+--------+--------+--------+--------+
```

---

# 8. ADD — Addition

### Opcode

```text
1011
```

### Assembly Syntax

```text
ADD Rdest, Rsrc1, Rsrc2
```

### Operation

```text
Rdest ← Rsrc1 + Rsrc2
```

### Example

```text
R2 = 0x55
R5 = 0xAA

ADD R1, R2, R5
```

Result:

```text
R1 = 0xFF
```

The ALU also generates a carry/status output.

For example:

```text
0xFF + 0x55 = 0x54
```

with:

```text
Carry = 1
```

---

# 9. SUB — Subtraction

### Opcode

```text
1100
```

### Assembly Syntax

```text
SUB Rdest, Rsrc1, Rsrc2
```

### Operation

```text
Rdest ← Rsrc1 - Rsrc2
```

### Example

```text
R2 = 0xAA
R1 = 0x55

SUB R5, R2, R1
```

Result:

```text
R5 = 0x55
```

The current implementation sets the status output when:

```text
Rsrc1 < Rsrc2
```

which represents a borrow condition.

Example:

```text
0x55 - 0xFF = 0x56
```

with:

```text
Borrow = 1
```

---

# 10. XOR — Bitwise XOR

### Opcode

```text
1101
```

### Assembly Syntax

```text
XOR Rdest, Rsrc1, Rsrc2
```

### Operation

```text
Rdest ← Rsrc1 ^ Rsrc2
```

### Example

```text
R2 = 0x55
R9 = 0xAA

XOR R1, R2, R9
```

Result:

```text
R1 = 0xFF
```

---

# 11. INC — Increment

### Opcode

```text
1110
```

### Assembly Syntax

```text
INC Rsrc, Rdest
```

### Operation

```text
Rdest ← Rsrc + 1
```

### Example

```text
INC R3, R3
```

If:

```text
R3 = 0x0F
```

then:

```text
R3 = 0x10
```

For an overflow case:

```text
R6 = 0xFF

INC R6, R6
```

results in:

```text
R6 = 0x00
Status = 1
```

### Encoding

```text
+--------+--------+--------+--------+
|   E    | Rdest  |  Rsrc  |   0    |
+--------+--------+--------+--------+
```

---

# Register File

The processor contains **14 general-purpose registers**:

```text
R0
R1
R2
R3
R4
R5
R6
R7
R8
R9
R10
R11
R12
R13
```

Each register is:

```text
8 bits wide
```

The register file supports:

- Two asynchronous read ports
- One synchronous write port
- Active reset
- 8-bit register data

Conceptually:

```text
                 +-----------------------+
    r_reg1 ----->|                       |----> r_d1
                 |     REGISTER FILE     |
    r_reg2 ----->|                       |----> r_d2
                 |                       |
    w_reg  ----->|                       |
    w_d    ----->|                       |
    write   ----->|                       |
                 +-----------------------+
```

The two read ports allow instructions such as:

```text
ADD R4, R1, R2
```

to read both operands simultaneously.

---

# ALU

The ALU is an 8-bit arithmetic and logic unit.

It supports:

| Operation | Control Code |
|---|---|
| `NOT` | `000` |
| `AND` | `001` |
| `ORA` | `010` |
| `ADD` | `011` |
| `SUB` | `100` |
| `XOR` | `101` |
| `INC` | `110` |

The ALU produces:

```text
8-bit result
+
status/carry output
```

Conceptually:

```text
       in1 ----------------+
                           |
                           v
                     +-----------+
       in2 --------->|    ALU    |----> result
                     +-----------+
                           |
                           +----------> status/carry
```

---

# Control Unit

The control unit is a **combinational instruction decoder**.

It receives:

```text
opcode
R1
R2
R3
```

and generates the control signals needed by the datapath.

Important signals include:

```text
r_reg1
r_reg2
w_reg
write_en
alu_op
is_ldb
is_mvr
mux_new_data_out
mux_processor_stat_data_out
mux_new_processor_stat
```

For example, for:

```text
ADD R4, R1, R2
```

the control unit selects:

```text
Source 1 = R1
Source 2 = R2
Destination = R4
ALU operation = ADD
Register write = enabled
Status update = enabled
```

---

# Program Counter

The CPU contains an 8-bit program counter.

```text
PC = 8 bits
```

The PC:

- Resets to `0x00`
- Increments once per clock cycle
- Addresses the instruction ROM

The instruction memory therefore contains:

```text
256 instruction locations
```

with addresses:

```text
0x00 – 0xFF
```

---

# Instruction Memory

Instruction memory is implemented as:

```text
256 × 16-bit ROM
```

The program is loaded from:

```text
machine_code.hex
```

using:

```verilog
$readmemh("machine_code.hex", rom);
```

This separates the processor hardware from the program being executed.

A new program can therefore be tested by changing the machine-code file without modifying the CPU RTL.

---

# Processor Status

The CPU maintains a single processor status bit:

```text
processor_stat
```

The ALU generates a status/carry signal:

```text
alu_c
```

For arithmetic operations, this status is stored by the CPU.

The `RDS` instruction exposes the status through the output port.

The output format is:

```text
processor_stat = 0 → 0x00
processor_stat = 1 → 0x01
```

---

# Instruction Execution

The complete instruction flow is:

```text
Program Counter
      |
      v
Instruction Memory
      |
      v
16-bit Instruction
      |
      v
Instruction Decode
      |
      v
Control Unit
      |
      +----------------------+
      |                      |
      v                      v
Register File           Immediate Data
      |
      v
     ALU
      |
      +----------------------+
      |                      |
      v                      v
Register Writeback      Status Update
      |
      v
Output Register
      |
      v
CPU Output
```

---

# Example Instruction Execution

Consider:

```text
ADD R4, R1, R2
```

Assume:

```text
R1 = 0x42
R2 = 0x18
```

The instruction is fetched from instruction memory.

The control unit decodes:

```text
Opcode = ADD
Destination = R4
Source 1 = R1
Source 2 = R2
```

The register file outputs:

```text
r_d1 = 0x42
r_d2 = 0x18
```

The ALU performs:

```text
0x42 + 0x18 = 0x5A
```

The register file then receives:

```text
R4 ← 0x5A
```

The complete data path is:

```text
R1 ───────┐
          |
          v
        +-----+
R2 ---->| ALU |----> 0x5A ----> R4
        +-----+
```

---

# Custom Assembler

The project includes a Python assembler:

```text
assembler.py
```

The assembler converts human-readable assembly instructions from:

```text
program.txt
```

into hexadecimal machine code:

```text
machine_code.hex
```

The complete flow is:

```text
program.txt
     |
     v
assembler.py
     |
     v
machine_code.hex
     |
     v
Instruction ROM
     |
     v
Custom CPU
```

---

# Assembler Usage

Run:

```bash
python assembler.py
```

The assembler parses instructions such as:

```text
LDB R1, 0x42
LDB R2, 0x18
ADD R4, R1, R2
STB R4
```

and generates machine code such as:

```text
1142
1218
B412
2400
```

Each machine-code instruction is exactly **4 hexadecimal digits**, corresponding to the 16-bit instruction width.

---

# Demonstration Program

The following program tests the complete ISA:

```text
# Load immediate values

LDB R1, 0x55
LDB R2, 0xAA
LDB R3, 0x0F
LDB R6, 0xFF

# Register movement

MVR R1, R5

# Logical operations

NOT R1, R5
AND R2, R7, R1
ORA R2, R8, R1
XOR R2, R9, R1

# Arithmetic operations

ADD R2, R10, R1
ADD R6, R11, R1

# Read carry/status

RDS

# Subtraction

SUB R2, R12, R1
SUB R1, R13, R6

# Read borrow/status

RDS

# Normal increment

INC R3, R3
STB R3

# Increment overflow

INC R6, R6
STB R6
RDS
```

This tests:

- `LDB`
- `MVR`
- `NOT`
- `AND`
- `ORA`
- `XOR`
- `ADD`
- Addition carry
- `SUB`
- Subtraction borrow
- `RDS`
- `INC`
- Increment overflow
- `STB`

---

# Basic Verification Program

A simpler program used to verify the datapath is:

```text
LDB R1, 0x42
LDB R2, 0x18
LDB R3, 0x0F

ADD R4, R1, R2
SUB R5, R1, R2
XOR R4, R4, R5

INC R4, R4
AND R4, R4, R3
STB R4
```

The expected execution is:

```text
R1 = 0x42
R2 = 0x18
R3 = 0x0F

ADD:
R4 = 0x42 + 0x18
R4 = 0x5A

SUB:
R5 = 0x42 - 0x18
R5 = 0x2A

XOR:
R4 = 0x5A ^ 0x2A
R4 = 0x70

INC:
R4 = 0x71

AND:
R4 = 0x71 & 0x0F
R4 = 0x01

STB:
OUT = 0x01
```

Expected final output:

```text
OUT = 8'h01
```

---

# Simulation

The project includes a Verilog testbench:

```text
final_tb.v
```

The testbench:

1. Generates the system clock.
2. Applies the active-low reset.
3. Releases reset.
4. Allows the CPU to execute instructions.
5. Monitors the CPU output.
6. Generates a VCD waveform.
7. Terminates the simulation after a fixed time.

---

# Compiling the CPU

Using Icarus Verilog:

```bash
iverilog -o cpu_sim final.v final_tb.v
```

If compilation succeeds, run:

```bash
vvp cpu_sim
```

---

# GTKWave Verification

The testbench generates:

```text
cpu_wave.vcd
```

Open it using:

```bash
gtkwave cpu_wave.vcd
```

Useful signals for debugging include:

```text
uut.clk
uut.rst_n
uut.rst
uut.pc

uut.inst_word
uut.opcode
uut.r1
uut.r2
uut.r3
uut.in_data

uut.r_reg1
uut.r_reg2
uut.w_reg
uut.write_en

uut.r_d1
uut.r_d2

uut.alu_op_ctrl
uut.alu_out
uut.alu_c

uut.write_data

uut.data_out
uut.processor_stat
```

The internal register file can also be inspected:

```text
uut.RF1.reg_data[0]
uut.RF1.reg_data[1]
uut.RF1.reg_data[2]
...
```

This allows the CPU to be debugged at the signal level.

---

# Verification Flow

The processor was verified by comparing expected instruction behavior against RTL simulation.

For example:

```text
Assembly
   |
   v
Assembler
   |
   v
Machine Code
   |
   v
Instruction ROM
   |
   v
Instruction Decode
   |
   v
Register File
   |
   v
ALU
   |
   v
Register Writeback
   |
   v
Output
```

GTKWave was used to inspect the internal signals and verify that instructions were being decoded and executed correctly.

---

# Project Structure

```text
Custom-8bit-CPU/
│
├── final.v
│       CPU RTL
│
├── final_tb.v
│       Verilog testbench
│
├── assembler.py
│       Custom ISA assembler
│
├── program.txt
│       Assembly program
│
├── machine_code.hex
│       Generated machine code
│
├── README.md
│       Project documentation
│
└── cpu_wave.vcd
        Generated simulation waveform
```

Generated simulation files such as `cpu_wave.vcd` and `cpu_sim` can be excluded from Git.

Recommended `.gitignore`:

```gitignore
*.vcd
cpu_sim
```

---

# Design Decisions

## Why 8-bit?

An 8-bit datapath keeps the processor architecture manageable while still allowing the implementation of:

- Registers
- ALU
- Instruction decoding
- Arithmetic operations
- Logical operations
- Status flags
- Machine-code instructions
- A complete datapath and control unit

---

## Why 16-bit instructions?

A 16-bit instruction provides enough space for:

```text
4-bit opcode
+
4-bit register fields
+
8-bit immediate values where required
```

This allows both register-based operations and immediate instructions to coexist in the same instruction width.

---

## Why a Custom ISA?

Instead of implementing an existing ISA such as RISC-V or ARM, the instruction set was designed specifically for this CPU.

This allowed direct control over:

- Opcode allocation
- Instruction encoding
- Register usage
- ALU operations
- Control signals
- Datapath requirements

The ISA was then implemented directly in the control unit and verified using the custom assembler.

---

# What I Learned

This project provided practical experience with:

- RTL design using Verilog
- Digital logic design
- CPU datapath architecture
- Instruction Set Architecture
- Custom instruction encoding
- Register-file design
- ALU design
- Combinational control logic
- Sequential logic
- Processor status handling
- Instruction memory
- Machine-code representation
- Python-based assembler development
- Verilog testbench development
- RTL simulation
- GTKWave waveform debugging
- Hardware-level debugging

Most importantly, the project connected individual digital-design concepts into a complete processor:

```text
Logic Gates
     |
     v
Combinational Circuits
     |
     v
Sequential Circuits
     |
     v
Registers + ALU
     |
     v
Datapath + Control Unit
     |
     v
Instruction Set Architecture
     |
     v
Complete CPU
```

---

# Future Improvements

Possible future extensions include:

- Branch instructions
- Jump instructions
- Conditional branching
- Additional processor status flags
- Stack support
- Memory-mapped I/O
- Separate instruction and data memory
- Larger register file
- Multi-cycle execution
- Pipelined execution
- Interrupt support
- FPGA implementation
- Automated assembler validation
- More extensive instruction-level verification

These features are **not part of the current implementation**.

---

# ISA Quick Reference

```text
DATA MOVEMENT / OUTPUT
────────────────────────────────────────

0000  MVR   Rdest ← Rsrc
0001  LDB   Rdest ← Immediate
0010  STB   OUT ← Rsrc
0011  RDS   OUT ← Processor Status


LOGICAL / ARITHMETIC
────────────────────────────────────────

1000  NOT   Rdest ← ~Rsrc
1001  AND   Rdest ← Rsrc1 & Rsrc2
1010  ORA   Rdest ← Rsrc1 | Rsrc2
1011  ADD   Rdest ← Rsrc1 + Rsrc2
1100  SUB   Rdest ← Rsrc1 - Rsrc2
1101  XOR   Rdest ← Rsrc1 ^ Rsrc2
1110  INC   Rdest ← Rsrc + 1


RESERVED
────────────────────────────────────────

0100
0101
0110
0111
1111
```

---

# Author

**Harshal V**

An 8-bit custom processor designed and implemented from scratch in Verilog, with a custom ISA, assembler, RTL simulation, and waveform-based verification.
