module enhanced_flash_model(
    input sck,
    input cs_n,
    inout dq0,
    inout dq1,
    inout dq2,
    inout dq3
);

// Flash memory array (1MB)
reg [7:0] flash_memory [0:1024*1024-1];

// QSPI protocol states
reg [7:0] command;
reg [23:0] address;
reg [7:0] data_out;
integer bit_count;
integer state;
integer i;

// States
localparam IDLE = 0, CMD = 1, ADDR = 2, DATA = 3;

// Initialize flash with CNN instructions and test program
initial begin
    // Initialize all memory to 0
    for (i = 0; i < 1024*1024; i = i + 1) begin
        flash_memory[i] = 8'h00;
    end
    
    // Load CNN instructions at specific addresses
    // Address 0x20000000: CNN Reset instruction
    flash_memory[0] = 8'h01;  // funct7[6:0] = 0000001
    flash_memory[1] = 8'h00;  // rs2[4:0] = 00000
    flash_memory[2] = 8'h00;  // rs1[4:0] = 00000
    flash_memory[3] = 8'h00;  // funct3[2:0] = 000
    flash_memory[4] = 8'h00;  // rd[4:0] = 00000
    flash_memory[5] = 8'h7F;  // opcode[6:0] = 1111111
    
    // Address 0x20000004: Load kernel to cache
    flash_memory[4] = 8'h02;  // funct7[6:0] = 0000010
    flash_memory[5] = 8'h01;  // rs2[4:0] = 00001
    flash_memory[6] = 8'h02;  // rs1[4:0] = 00010
    flash_memory[7] = 8'h00;  // funct3[2:0] = 000
    flash_memory[8] = 8'h00;  // rd[4:0] = 00000
    flash_memory[9] = 8'h7F;  // opcode[6:0] = 1111111
    
    // Address 0x20000008: Load image to cache
    flash_memory[8] = 8'h03;  // funct7[6:0] = 0000011
    flash_memory[9] = 8'h03;  // rs2[4:0] = 00011
    flash_memory[10] = 8'h04; // rs1[4:0] = 00100
    flash_memory[11] = 8'h00; // funct3[2:0] = 000
    flash_memory[12] = 8'h00; // rd[4:0] = 00000
    flash_memory[13] = 8'h7F; // opcode[6:0] = 1111111
    
    // Address 0x2000000C: Load image to PE
    flash_memory[12] = 8'h04; // funct7[6:0] = 0000100
    flash_memory[13] = 8'h03; // rs2[4:0] = 00011
    flash_memory[14] = 8'h04; // rs1[4:0] = 00100
    flash_memory[15] = 8'h00; // funct3[2:0] = 000
    flash_memory[16] = 8'h00; // rd[4:0] = 00000
    flash_memory[17] = 8'h7F; // opcode[6:0] = 1111111
    
    // Address 0x20000010: Load kernel to PE
    flash_memory[16] = 8'h08; // funct7[6:0] = 0001000
    flash_memory[17] = 8'h01; // rs2[4:0] = 00001
    flash_memory[18] = 8'h02; // rs1[4:0] = 00010
    flash_memory[19] = 8'h00; // funct3[2:0] = 000
    flash_memory[20] = 8'h00; // rd[4:0] = 00000
    flash_memory[21] = 8'h7F; // opcode[6:0] = 1111111
    
    // Address 0x20000014: Configure crossbar and PE mode
    flash_memory[20] = 8'h0C; // funct7[6:0] = 0001100
    flash_memory[21] = 8'h15; // rs2[4:0] = 10101
    flash_memory[22] = 8'h16; // rs1[4:0] = 10110
    flash_memory[23] = 8'h00; // funct3[2:0] = 000
    flash_memory[24] = 8'h00; // rd[4:0] = 00000
    flash_memory[25] = 8'h7F; // opcode[6:0] = 1111111
    
    // Address 0x20000018: Start computation
    flash_memory[24] = 8'h0D; // funct7[6:0] = 0001101
    flash_memory[25] = 8'h17; // rs2[4:0] = 10111
    flash_memory[26] = 8'h18; // rs1[4:0] = 11000
    flash_memory[27] = 8'h00; // funct3[2:0] = 000
    flash_memory[28] = 8'h00; // rd[4:0] = 00000
    flash_memory[29] = 8'h7F; // opcode[6:0] = 1111111
    
    // Address 0x2000001C: Store CNN result
    flash_memory[28] = 8'h05; // funct7[6:0] = 0000101
    flash_memory[29] = 8'h07; // rs2[4:0] = 00111
    flash_memory[30] = 8'h08; // rs1[4:0] = 01000
    flash_memory[31] = 8'h00; // funct3[2:0] = 000
    flash_memory[32] = 8'h00; // rd[4:0] = 00000
    flash_memory[33] = 8'h7F; // opcode[6:0] = 1111111
    
    // Address 0x20000020: Store result to external
    flash_memory[32] = 8'h06; // funct7[6:0] = 0000110
    flash_memory[33] = 8'h07; // rs2[4:0] = 00111
    flash_memory[34] = 8'h08; // rs1[4:0] = 01000
    flash_memory[35] = 8'h00; // funct3[2:0] = 000
    flash_memory[36] = 8'h00; // rd[4:0] = 00000
    flash_memory[37] = 8'h7F; // opcode[6:0] = 1111111
    
    // Load some test data for image processing
    // Address 0x20000100: Image data
    flash_memory[256] = 8'h12; // Sample image pixel 1
    flash_memory[257] = 8'h34;
    flash_memory[258] = 8'h56;
    flash_memory[259] = 8'h78;
    
    flash_memory[260] = 8'h87; // Sample image pixel 2
    flash_memory[261] = 8'h65;
    flash_memory[262] = 8'h43;
    flash_memory[263] = 8'h21;
    
    // Address 0x20000200: Kernel data
    flash_memory[512] = 8'h01; // Sample kernel value 1
    flash_memory[513] = 8'h02;
    flash_memory[514] = 8'h03;
    flash_memory[515] = 8'h04;
    
    flash_memory[516] = 8'h05; // Sample kernel value 2
    flash_memory[517] = 8'h06;
    flash_memory[518] = 8'h07;
    flash_memory[519] = 8'h08;
    
    $display("Enhanced Flash model initialized with CNN instructions and test data");
    $display("CNN Instructions loaded at addresses:");
    $display("  0x20000000: Reset");
    $display("  0x20000004: Load kernel to cache");
    $display("  0x20000008: Load image to cache");
    $display("  0x2000000C: Load image to PE");
    $display("  0x20000010: Load kernel to PE");
    $display("  0x20000014: Configure crossbar");
    $display("  0x20000018: Start computation");
    $display("  0x2000001C: Store CNN result");
    $display("  0x20000020: Store to external");
end

// QSPI protocol implementation
always @(posedge sck or posedge cs_n) begin
    if (cs_n) begin
        state <= IDLE;
        bit_count <= 0;
    end else begin
        case (state)
            IDLE: begin
                state <= CMD;
                bit_count <= 0;
            end
            CMD: begin
                command[7-bit_count] <= dq0;
                bit_count <= bit_count + 1;
                if (bit_count == 7) begin
                    state <= ADDR;
                    bit_count <= 0;
                end
            end
            ADDR: begin
                address[23-bit_count] <= dq0;
                bit_count <= bit_count + 1;
                if (bit_count == 23) begin
                    state <= DATA;
                    bit_count <= 0;
                    data_out <= flash_memory[address];
                    $display("FLASH: Reading address 0x%h, data=0x%h", address, flash_memory[address]);
                end
            end
            DATA: begin
                bit_count <= bit_count + 1;
            end
        endcase
    end
end

// Data output (simplified QSPI read)
assign dq1 = (state == DATA) ? data_out[7-bit_count%8] : 1'bz;
assign dq2 = 1'bz;
assign dq3 = 1'bz;

endmodule 