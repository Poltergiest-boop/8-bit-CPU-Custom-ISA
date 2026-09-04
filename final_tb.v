`timescale 1ns/1ps
`default_nettype none

module cpu_tb;

    // 1. Declare the interface signals
    reg clk;
    reg rst_n;
    wire [7:0] out;

    // 2. Instantiate the CPU Motherboard (Unit Under Test)
    simple_8bit_cpu uut (
        .clk(clk),
        .rst_n(rst_n),
        .out(out)
    );

    // 3. Generate the System Clock (Toggles every 5 time units)
    always #5 clk = ~clk;

    // 4. Test Sequence & Logging
    initial begin
        // The Magic Print Statement! 
        // Note: I added 'uut.pc' so they can watch the Program Counter count up line-by-line.
        $monitor("Time: %0t | Reset: %b | PC: %d | CPU Output Port: 8'h%h", $time, rst_n, uut.pc, out);
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, cpu_tb);
        $display("--- Booting up Custom 8-Bit CPU ---");

        // System Boot Sequence
        clk = 0;
        rst_n = 0; // Hold reset ACTIVE (0) to clear all registers
        
        // Wait 12 nanoseconds, then pull Reset HIGH (1) to start the CPU
        #12;
        rst_n = 1;

        // Let the CPU run long enough to execute all instructions in the text file / ROM
        // You can increase this number if you write a much longer assembly program!
        #150;

        $display("--- Simulation Complete ---");
        $finish;
    end

endmodule