# assembler.py

# ==============================
# Custom 8-bit CPU Assembler
# ==============================

opcodes = {
    "MVR": "0",
    "LDB": "1",
    "STB": "2",
    "RDS": "3",
    "NOT": "8",
    "AND": "9",
    "ORA": "A",
    "ADD": "B",
    "SUB": "C",
    "XOR": "D",
    "INC": "E"
}


def register_number(reg):
    """Convert R1 / r1 into a single hexadecimal digit."""
    reg = reg.upper().replace("R", "")
    num = int(reg)

    if num < 0 or num > 13:
        raise ValueError(f"Invalid register: R{num}. Valid registers are R0-R13.")

    return f"{num:X}"


def immediate_value(value):
    """Convert 0x55 / 55 into exactly two hexadecimal digits."""
    value = value.upper().replace("0X", "")
    num = int(value, 16)

    if num < 0 or num > 255:
        raise ValueError(f"Immediate value out of range: {value}")

    return f"{num:02X}"


with open("program.txt", "r") as f_in, open("machine_code.hex", "w") as f_out:

    for line_number, line in enumerate(f_in, 1):

        # Remove comments
        line = line.split("#")[0].strip()

        if not line:
            continue

        # Remove commas
        parts = line.replace(",", " ").split()

        command = parts[0].upper()

        try:

            # ==============================
            # LDB Rdest, immediate
            # ==============================
            if command == "LDB":

                r_dest = register_number(parts[1])
                data = immediate_value(parts[2])

                machine_code = (
                    opcodes[command]
                    + r_dest
                    + data
                )

            # ==============================
            # MVR Rsrc, Rdest
            # ==============================
            elif command == "MVR":

                r_src = register_number(parts[1])
                r_dest = register_number(parts[2])

                machine_code = (
                    opcodes[command]
                    + r_src
                    + r_dest
                    + "0"
                )

            # ==============================
            # STB Rsrc
            # ==============================
            elif command == "STB":

                r_src = register_number(parts[1])

                machine_code = (
                    opcodes[command]
                    + r_src
                    + "00"
                )

            # ==============================
            # RDS
            # ==============================
            elif command == "RDS":

                machine_code = "3000"

            # ==============================
            # NOT Rsrc, Rdest
            # ==============================
            elif command == "NOT":

                r_src = register_number(parts[1])
                r_dest = register_number(parts[2])

                machine_code = (
                    opcodes[command]
                    + r_src
                    + r_dest
                    + "0"
                )

            # ==============================
            # ALU:
            # AND / ORA / ADD / SUB / XOR
            #
            # Format:
            # OP Rdest, Rsrc1, Rsrc2
            # ==============================
            elif command in ["AND", "ORA", "ADD", "SUB", "XOR"]:

                r_dest = register_number(parts[1])
                r_src1 = register_number(parts[2])
                r_src2 = register_number(parts[3])

                machine_code = (
                    opcodes[command]
                    + r_dest
                    + r_src1
                    + r_src2
                )

            # ==============================
            # INC Rsrc, Rdest
            # ==============================
            elif command == "INC":

                r_src = register_number(parts[1])
                r_dest = register_number(parts[2])

                machine_code = (
                    opcodes[command]
                    + r_dest
                    + r_src
                    + "0"
                )

            else:
                raise ValueError(f"Unknown instruction: {command}")

            # Safety check
            if len(machine_code) != 4:
                raise ValueError(
                    f"Invalid machine code '{machine_code}' "
                    f"(must be exactly 4 hex digits)"
                )

            f_out.write(machine_code + "\n")

            print(f"{line.strip():25} -> {machine_code}")

        except Exception as e:
            print(f"ERROR on line {line_number}: {line.strip()}")
            print(f"       {e}")
            sys.exit(1)


print("\nAssembly complete!")
print("Generated machine_code.hex")