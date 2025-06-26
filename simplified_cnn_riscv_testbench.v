`timescale 1ns/1ps

module simplified_cnn_riscv_testbench;

// Clock and reset signals
reg hfextclk;     // 16MHz main clock
reg external_reset_n;

// GPIO signals for image data input
reg [31:0] gpio_a_inputs;    // Image data input
reg [31:0] gpio_b_inputs;    // Control signals
wire [31:0] gpio_a_outputs;
wire [31:0] gpio_b_outputs;
wire [31:0] gpio_a_oe;
wire [31:0] gpio_b_oe;

// QSPI flash interface
wire qspi_sck;
wire qspi_cs;
wire qspi_dq0, qspi_dq1, qspi_dq2, qspi_dq3;
assign {qspi_dq3, qspi_dq2, qspi_dq1, qspi_dq0} = 4'b0;

// CNN accelerator interface signals
wire cnn_nice_active;
wire cnn_nice_rsp_err;

// CNN accelerator interface signals (from CPU to Accelerator)
reg cnn_nice_req_valid;
wire cnn_nice_req_ready;
reg [31:0] cnn_nice_req_inst;
reg [31:0] cnn_nice_req_rs1;
reg [31:0] cnn_nice_req_rs2;
wire cnn_nice_rsp_valid;
wire cnn_nice_rsp_ready;
wire [31:0] cnn_nice_rsp_rdat;
wire cnn_mem_holdup;

// Memory interface for CNN Accelerator (from Accelerator to Memory Model)
wire cnn_icb_cmd_valid;
wire cnn_icb_cmd_ready;
wire [31:0] cnn_icb_cmd_addr;
wire cnn_icb_cmd_read;
wire [31:0] cnn_icb_cmd_wdata;
wire [1:0] cnn_icb_cmd_size;

// Memory model response signals (from Memory Model to Accelerator)
reg  nice_icb_rsp_valid;
reg  [31:0] nice_icb_rsp_rdata;
reg  nice_icb_rsp_err;

// Test control signals
reg [7:0] test_phase;
reg [31:0] image_data_counter;
reg [31:0] instruction_counter;
reg test_complete;

// Clock generation
initial hfextclk = 0;
always #31.25 hfextclk = ~hfextclk;  // 16MHz

// Simplified RISC-V SoC (mock for testing)
// In a real implementation, this would be the actual e203_soc_top
assign gpio_a_outputs = gpio_a_inputs;
assign gpio_b_outputs = gpio_b_inputs;
assign gpio_a_oe = 32'h00000001;  // Enable output
assign gpio_b_oe = 32'h00000001;  // Enable output

// The testbench memory model is always ready to accept commands
assign cnn_icb_cmd_ready = 1'b1;

// CNN accelerator instantiation
cnn_top_module u_cnn_accelerator(
    .nice_clk(hfextclk),
    .rst_n(external_reset_n),
    
    // External interface
    .nice_req_valid(cnn_nice_req_valid),
    .nice_req_ready(cnn_nice_req_ready),
    .nice_rsp_valid(cnn_nice_rsp_valid),
    .nice_rsp_ready(cnn_nice_rsp_ready),
    .nice_rsp_rdat(cnn_nice_rsp_rdat),
    .nice_req_inst(cnn_nice_req_inst),
    .nice_req_rs1(cnn_nice_req_rs1),
    .nice_req_rs2(cnn_nice_req_rs2),
    .nice_mem_holdup(cnn_mem_holdup),
    .nice_active(cnn_nice_active),
    .nice_rsp_err(cnn_nice_rsp_err),
    
    // Memory interface
    .nice_icb_cmd_valid(cnn_icb_cmd_valid),
    .nice_icb_cmd_ready(cnn_icb_cmd_ready),
    .nice_icb_cmd_addr(cnn_icb_cmd_addr),
    .nice_icb_cmd_read(cnn_icb_cmd_read),
    .nice_icb_cmd_wdata(cnn_icb_cmd_wdata),
    .nice_icb_cmd_rdata(nice_icb_rsp_rdata),
    .nice_icb_cmd_size(cnn_icb_cmd_size),
    .nice_icb_rsp_valid(nice_icb_rsp_valid),
    .nice_icb_rsp_ready(cnn_nice_rsp_ready),
    .nice_icb_rsp_rdata(nice_icb_rsp_rdata),
    .nice_icb_rsp_err(nice_icb_rsp_err)
);

// Simple ICB memory model for the CNN accelerator
always @(posedge hfextclk or negedge external_reset_n) begin
    if (!external_reset_n) begin
        nice_icb_rsp_valid <= 1'b0;
        nice_icb_rsp_rdata <= 32'b0;
        nice_icb_rsp_err   <= 1'b0;
    end else begin
        // By default, response is not valid
        nice_icb_rsp_valid <= 1'b0;

        // When the accelerator makes a valid request and we are ready
        if (cnn_icb_cmd_valid && cnn_icb_cmd_ready) begin
            // Assert valid for one cycle for the response
            nice_icb_rsp_valid <= 1'b1;
            if (cnn_icb_cmd_read) begin
                // Provide some dummy data for reads
                nice_icb_rsp_rdata <= 32'hDEADBEEF; 
                $display("SIM_MEM: Read from 0x%h, returning 0x%h", cnn_icb_cmd_addr, 32'hDEADBEEF);
            end else begin
                // Acknowledge writes
                $display("SIM_MEM: Write to 0x%h with data 0x%h", cnn_icb_cmd_addr, cnn_icb_cmd_wdata);
            end
        end
    end
end

// Main test sequence
initial begin
    // Initialize signals
    external_reset_n = 0;
    gpio_a_inputs = 32'h0;
    gpio_b_inputs = 32'h0;
    test_phase = 0;
    image_data_counter = 0;
    instruction_counter = 0;
    test_complete = 0;
    
    $display("TESTBENCH: Starting simplified CNN-RISC-V testbench at %t", $time);
    
    // Hold reset for a while
    #1000;
    external_reset_n = 1;
    $display("TESTBENCH: Reset released at %t", $time);
    
    // Wait for system to stabilize
    #5000;
    
    // Run the complete CNN pipeline
    run_cnn_pipeline();
    
    // Let simulation run for a while
    #50000;
    
    // Print final statistics
    print_statistics();
    
    test_complete = 1;
    $display("TESTBENCH: Simulation complete at %t", $time);
    $finish;
end

// Task to run complete CNN pipeline
task run_cnn_pipeline;
    begin
        $display("TEST: Starting CNN pipeline at %t", $time);
        
        // Phase 1: Reset and Initialize
        test_phase = 1;
        $display("TEST: Phase 1 - Reset and Initialize");
        send_cnn_instruction(32'b0000001_00000_00000_0_0_0_00000_1111111); // Reset
        #1000;
        
        // Phase 2: Load Data
        test_phase = 2;
        $display("TEST: Phase 2 - Load Data");
        send_image_data(32'h12345678); // Sample image data
        send_cnn_instruction(32'b0000010_00001_00010_0_0_0_00000_1111111); // Load kernel
        #1000;
        send_cnn_instruction(32'b0000011_00011_00100_0_0_0_00000_1111111); // Load image
        #1000;
        
        // Phase 3: Configure Processing
        test_phase = 3;
        $display("TEST: Phase 3 - Configure Processing");
        send_cnn_instruction(32'b0000100_00011_00100_0_0_0_00000_1111111); // Load image to PE
        #1000;
        send_cnn_instruction(32'b0001000_00001_00010_0_0_0_00000_1111111); // Load kernel to PE
        #1000;
        send_cnn_instruction(32'b0001100_10101_10110_0_0_0_00000_1111111); // Configure crossbar
        #1000;
        
        // Phase 4: Execute CNN Layers
        test_phase = 4;
        $display("TEST: Phase 4 - Execute CNN Layers");
        send_cnn_instruction(32'b0001101_10111_11000_0_0_0_00000_1111111); // Start computation
        #5000; // Wait for computation to complete
        
        // Phase 5: Store Results
        test_phase = 5;
        $display("TEST: Phase 5 - Store Results");
        send_cnn_instruction(32'b0000101_00111_01000_0_0_0_00000_1111111); // Store CNN result
        #1000;
        send_cnn_instruction(32'b0000110_00111_01000_0_0_0_00000_1111111); // Store to external
        #1000;
        
        $display("TEST: CNN pipeline completed at %t", $time);
    end
endtask

// Task to send image data through GPIO
task send_image_data;
    input [31:0] image_data;
    begin
        @(posedge hfextclk);
        gpio_a_inputs = image_data;
        image_data_counter = image_data_counter + 1;
        $display("TEST: Sending image data 0x%h through GPIO at %t", image_data, $time);
        #1000; // Wait for processing
    end
endtask

// Task to send CNN instruction through QSPI
task send_cnn_instruction;
    input [31:0] instruction;
    begin
        @(posedge hfextclk);
        cnn_nice_req_valid <= 1'b1;
        cnn_nice_req_inst <= instruction;
        cnn_nice_req_rs1 <= 32'hAAAAAAAA; // Dummy data for now
        cnn_nice_req_rs2 <= 32'hBBBBBBBB; // Dummy data for now
        instruction_counter = instruction_counter + 1;
        $display("TEST: Sending CNN instruction 0x%h at %t", instruction, $time);
        
        // Wait for accelerator to be ready
        wait(cnn_nice_req_ready);
        @(posedge hfextclk);
        cnn_nice_req_valid <= 1'b0;

        #500; // Wait for instruction processing
    end
endtask

// Task to print final statistics
task print_statistics;
    begin
        $display("TESTBENCH: Final Statistics at %t", $time);
        $display("  Test phase reached: %d", test_phase);
        $display("  Image data sent: %d", image_data_counter);
        $display("  Instructions sent: %d", instruction_counter);
        $display("  GPIO data: 0x%h", gpio_a_outputs);
        $display("  CNN request valid: %b", cnn_nice_req_valid);
        $display("  CNN request ready: %b", cnn_nice_req_ready);
        $display("  CNN response valid: %b", cnn_nice_rsp_valid);
        $display("  CNN response data: 0x%h", cnn_nice_rsp_rdat);
    end
endtask

// Continuous monitoring
always @(posedge hfextclk) begin
    // Monitor GPIO activity
    if (gpio_a_oe != 0) begin
        $display("MONITOR: GPIO read detected at %t, data=0x%h", $time, gpio_a_outputs);
    end
    
    // Monitor QSPI activity
    if (qspi_cs == 0) begin
        $display("MONITOR: QSPI read detected at %t", $time);
    end
    
    // Monitor CNN interface
    if (cnn_nice_req_valid && cnn_nice_req_ready) begin
        $display("MONITOR: CNN request at %t, inst=0x%h, rs1=0x%h, rs2=0x%h", 
                 $time, cnn_nice_req_inst, cnn_nice_req_rs1, cnn_nice_req_rs2);
    end
    
    if (cnn_nice_rsp_valid && cnn_nice_rsp_ready) begin
        $display("MONITOR: CNN response at %t, data=0x%h", $time, cnn_nice_rsp_rdat);
    end
end

// Error detection
always @(posedge hfextclk) begin
    if (cnn_nice_req_valid && !cnn_nice_req_ready && $time > 10000) begin
        $display("ERROR: CNN request stuck at %t", $time);
    end
    
    if (cnn_nice_rsp_valid && !cnn_nice_rsp_ready && $time > 10000) begin
        $display("ERROR: CNN response stuck at %t", $time);
    end
    
    if (test_phase == 4 && $time > 100000) begin
        $display("ERROR: CNN computation timeout at %t", $time);
    end
end

// Waveform dump
initial begin
    $dumpfile("simplified_cnn_riscv.vcd");
    $dumpvars(0, simplified_cnn_riscv_testbench);
end

endmodule 