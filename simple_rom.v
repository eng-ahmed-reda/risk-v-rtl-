`timescale 1ns/1ps

module simple_rom (
    input wire        clk,
    input wire        req,
    input wire [31:0]  addr,
    output reg [31:0] rdata
);

    // This ROM contains a simple program to read from GPIOA and write to GPIOA
    // It is a placeholder for a real program loaded from flash.

    reg [31:0] mem [0:7];

    // Simple RISC-V Program:
    // 0x0000: lui  a0, 0x10012   // a0 = 0x10012000 (GPIO Base Address)
    // 0x0004: lw   a1, 0(a0)     // a1 = *a0 (Read from GPIOA input)
    // 0x0008: sw   a1, 4(a0)     // * (a0+4) = a1 (Write to GPIOA output)
    // 0x000C: j    0x0004        // Loop back to read again
    initial begin
        mem[0] = 32'h10012537; // lui a0, 0x10012
        mem[1] = 32'h00052583; // lw  a1, 0(a0)
        mem[2] = 32'h00b52223; // sw  a1, 4(a0)
        mem[3] = 32'hffdfedef; // jal ra, -4 -> jumps to 0x0004
        mem[4] = 32'h00000000;
        mem[5] = 32'h00000000;
        mem[6] = 32'h00000000;
        mem[7] = 32'h00000000;
    end

    always @(posedge clk) begin
        if (req) begin
            rdata <= mem[addr[4:2]]; // Simple addressing for this small ROM
        end
    end

endmodule 