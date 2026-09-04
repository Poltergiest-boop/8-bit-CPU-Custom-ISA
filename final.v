`default_nettype none

// ====================================================================
// --- MACROS & DEFINES ---
// ====================================================================
// ISA Opcodes 
`define MVR 4'b0000            // Move Register
`define LDB 4'b0001            // Load Byte into Register
`define STB 4'b0010            // Store Byte from Register
`define RDS 4'b0011            // Read (store) processor status

// ALU Opcodes 
`define NOT 4'b1000
`define AND 4'b1001
`define ORA 4'b1010
`define ADD 4'b1011
`define SUB 4'b1100
`define XOR 4'b1101
`define INC 4'b1110

// ALU Internal Routing Codes 
`define ALU_NOT  3'b000
`define ALU_AND  3'b001
`define ALU_ORA  3'b010
`define ALU_ADD  3'b011
`define ALU_SUB  3'b100
`define ALU_XOR  3'b101
`define ALU_INC  3'b110

// ====================================================================
// --- 1. TOP MODULE (The CPU Motherboard) ---
// ====================================================================
module simple_8bit_cpu (
    input  wire       clk,      // System Clock
    input  wire       rst_n,    // Reset (Active Low)
    output wire [7:0] out       // CPU Output Port
);

    wire rst = !rst_n;

    // -- A. PROGRAM COUNTER --
    reg [7:0] pc;
    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 8'b0000_0000;
        else     pc <= pc + 1;  // Count up every clock cycle!
    end

    // -- B. INSTRUCTION MEMORY (ROM) --
    wire [15:0] inst_word;
    inst_mem ROM (
        .addr(pc),
        .inst_out(inst_word)
    );

    // Decode the 16-bit instruction word into pieces
    wire [3:0] opcode  = inst_word[15:12];
    wire [3:0] r1      = inst_word[11:8];
    wire [3:0] r2      = inst_word[7:4];
    wire [3:0] r3      = inst_word[3:0];
    wire [7:0] in_data = inst_word[7:0]; 

    // -- C. CONTROL UNIT --
    wire write_en, is_ldb, is_mvr;
    wire mux_new_data_out, mux_processor_stat_data_out, mux_new_processor_stat;
    wire [2:0] alu_op_ctrl;
    wire [3:0] r_reg1, r_reg2, w_reg;

    control_unit CU (
        .opcode(opcode), .r1(r1), .r2(r2), .r3(r3),
        .r_reg1(r_reg1), .r_reg2(r_reg2), .w_reg(w_reg),
        .write_en(write_en), .alu_op(alu_op_ctrl),
        .is_ldb(is_ldb), .is_mvr(is_mvr),
        .mux_new_data_out(mux_new_data_out),
        .mux_processor_stat_data_out(mux_processor_stat_data_out),
        .mux_new_processor_stat(mux_new_processor_stat)
    );

    // -- D. DATAPATH (Registers & ALU) --
    wire [7:0] r_d1, r_d2, alu_out;
    wire alu_c;

    // Data Routing: Decide what data goes into the Register File
    wire [7:0] write_data = is_ldb ? in_data : (is_mvr ? r_d1 : alu_out);

    reg_file RF1(
        .clk(clk), .rst(rst),
        .write(write_en), .w_reg(w_reg), .w_d(write_data),
        .r_reg1(r_reg1), .r_reg2(r_reg2),
        .r_d1(r_d1), .r_d2(r_d2)
    );

    alu ALU1(
       .in1(r_d1), .in2(r_d2), .op(alu_op_ctrl),
       .out(alu_out), .c(alu_c)
    );

    // -- E. OUTPUT REGISTER --
    reg [7:0] data_out;
    reg processor_stat;
    assign out = data_out;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 8'b00000000;
            processor_stat <= 1'b0;
        end
        else begin
            if (mux_new_processor_stat) 
                processor_stat <= alu_c;
                
            if (mux_processor_stat_data_out) 
                data_out <= {7'b0000000, processor_stat};
            else if (mux_new_data_out) 
                data_out <= r_d1;
        end
    end
endmodule


// ====================================================================
// --- 2. CONTROL UNIT ---
// ====================================================================
module control_unit (
    input  wire [3:0] opcode, r1, r2, r3,
    output reg  [3:0] r_reg1, r_reg2, w_reg,
    output reg        write_en,
    output reg  [2:0] alu_op,
    output reg        is_ldb, is_mvr,
    output reg        mux_new_data_out, mux_processor_stat_data_out, mux_new_processor_stat
);
    always @(*) begin
        // Default zeroes to prevent latches
        r_reg1 = 4'b0000; r_reg2 = 4'b0000; w_reg = 4'b0000; write_en = 1'b0; alu_op = 3'b000;
        is_ldb = 1'b0; is_mvr = 1'b0; mux_new_data_out = 1'b0; 
        mux_processor_stat_data_out = 1'b0; mux_new_processor_stat = 1'b0;

        case(opcode)
            `MVR: begin r_reg1 = r1; w_reg = r2; write_en = 1; is_mvr = 1; end
            `LDB: begin w_reg = r1; write_en = 1; is_ldb = 1; end
            `STB: begin r_reg1 = r1; mux_new_data_out = 1; end
            `RDS: begin mux_processor_stat_data_out = 1; end
            
            `NOT: begin r_reg1 = r1; w_reg = r2; alu_op = `ALU_NOT; write_en = 1; mux_new_processor_stat = 1; end
            `AND: begin r_reg1 = r2; r_reg2 = r3; w_reg = r1; alu_op = `ALU_AND; write_en = 1; mux_new_processor_stat = 1; end
            `ORA: begin r_reg1 = r2; r_reg2 = r3; w_reg = r1; alu_op = `ALU_ORA; write_en = 1; mux_new_processor_stat = 1; end
            `ADD: begin r_reg1 = r2; r_reg2 = r3; w_reg = r1; alu_op = `ALU_ADD; write_en = 1; mux_new_processor_stat = 1; end
            `SUB: begin r_reg1 = r2; r_reg2 = r3; w_reg = r1; alu_op = `ALU_SUB; write_en = 1; mux_new_processor_stat = 1; end
            `XOR: begin r_reg1 = r2; r_reg2 = r3; w_reg = r1; alu_op = `ALU_XOR; write_en = 1; mux_new_processor_stat = 1; end
            `INC: begin r_reg1 = r2; w_reg = r1; alu_op = `ALU_INC; write_en = 1; mux_new_processor_stat = 1; end
        endcase
    end
endmodule


// ====================================================================
// --- 3. INSTRUCTION MEMORY (ROM) ---
// ====================================================================
module inst_mem (
    input  wire [7:0]  addr,
    output wire [15:0] inst_out
);
    // Create the memory array (256 slots, 16-bits wide)
    reg [15:0] rom [0:255];
    integer i;
    initial begin
        // Initialize everything to zero just to be safe
        for (i = 0; i < 256; i = i + 1) begin
            rom[i] = 16'h0000;
        end

        // THE MAGIC LINE: Load the text file into the ROM!
        $readmemh("machine_code.hex", rom);
    end
    
    assign inst_out = rom[addr];
endmodule

// ====================================================================
// --- 4. REGISTER FILE ---
// ====================================================================
module reg_file #(
    parameter BIT_WIDTH_REG = 8,
    parameter REG_COUNT = 14,
    parameter LOG_REG_COUNT = 4
)(
    input                               clk,
    input                               rst,
    input                               write,
    input       [LOG_REG_COUNT-1:0]     w_reg,
    input       [BIT_WIDTH_REG-1:0]     w_d,
    input       [LOG_REG_COUNT-1:0]     r_reg1,
    input       [LOG_REG_COUNT-1:0]     r_reg2,
    output wire [BIT_WIDTH_REG-1:0]     r_d1,
    output wire [BIT_WIDTH_REG-1:0]     r_d2
);
    reg [BIT_WIDTH_REG-1:0] reg_data [0:REG_COUNT-1];

    assign r_d1 = reg_data[r_reg1];
    assign r_d2 = reg_data[r_reg2];

    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < REG_COUNT; i = i + 1) begin
                reg_data[i] <= {BIT_WIDTH_REG{1'b0}};
            end
        end
        else if(write) begin
            reg_data[w_reg] <= w_d;
        end
    end
endmodule


// ====================================================================
// --- 5. ALU ---
// ====================================================================
module alu #(
    parameter BIT_WIDTH_REG = 8
)(
   input      [BIT_WIDTH_REG-1:0] in1,
   input      [BIT_WIDTH_REG-1:0] in2,
   input      [2:0]               op,
   output reg [BIT_WIDTH_REG-1:0] out,
   output reg                     c
);
    reg [BIT_WIDTH_REG:0] temp;

    always @(*) begin
        case(op)
            `ALU_NOT: begin
                    out = ~in1;
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
            end
            `ALU_AND: begin
                    out = in1 & in2;
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
            end
            `ALU_ORA: begin
                    out = in1 | in2;
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
            end
            `ALU_ADD: begin
                    temp = {1'b0, in1} + {1'b0, in2};
                    out = temp[BIT_WIDTH_REG-1:0];
                    c = temp[BIT_WIDTH_REG];
            end
            `ALU_SUB: begin
                    out = in1 - in2;
                    c = in1 < in2;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
            end
            `ALU_XOR: begin
                    out = in1 ^ in2;
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
            end
            `ALU_INC: begin
                    out = in1 + 1;
                    c = in1[7] & ~out[7];
                    temp = {BIT_WIDTH_REG+1{1'bx}};
            end
            default: begin
                    out = {BIT_WIDTH_REG{1'b0}};
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
            end
        endcase
    end
endmodule