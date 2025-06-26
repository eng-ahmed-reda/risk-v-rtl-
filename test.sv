`include "e203_defines.sv"

module tb_e203_cpu_top;

  // Clock and Reset
  reg clk;
  reg rst_n;
  reg test_mode;

  // PC Reset Vector
  reg [32-1:0] pc_rtvec;

  // Core outputs (inspection signals)
  wire [32-1:0] inspect_pc;
  wire inspect_dbg_irq;
  wire inspect_mem_cmd_valid;
  wire inspect_mem_cmd_ready;
  wire inspect_mem_rsp_valid;
  wire inspect_mem_rsp_ready;
  wire inspect_core_clk;
  wire core_csr_clk;
  wire core_wfi;
  wire tm_stop;

  // Debug interface (can be tied off for basic testing)
  wire dbg_irq_r;
  wire [32-1:0] cmt_dpc;
  wire cmt_dpc_ena;
  wire [2:0] cmt_dcause;
  wire cmt_dcause_ena;
  wire wr_dcsr_ena;
  wire wr_dpc_ena;
  wire wr_dscratch_ena;
  wire [31:0] wr_csr_nxt;
  
  reg [31:0] dcsr_r;
  reg [32-1:0] dpc_r;
  reg [31:0] dscratch_r;
  reg dbg_mode;
  reg dbg_halt_r;
  reg dbg_step_r;
  reg dbg_ebreakm_r;
  reg dbg_stopcycle;
  reg dbg_irq_a;

  // Hart ID and Interrupts
  reg [1-1:0] core_mhartid;
  reg ext_irq_a;
  reg sft_irq_a;
  reg tmr_irq_a;

  // TCM Power Management
  reg tcm_sd;
  reg tcm_ds;

  // NICE (Network Interface for Custom Extensions) Interface Signals
  // Command channel from CPU to accelerator
  wire nice_mem_holdup;
  wire nice_icb_cmd_valid;
  reg nice_icb_cmd_ready;
  wire [32-1:0] nice_icb_cmd_addr;
  wire nice_icb_cmd_read;
  wire [32-1:0] nice_icb_cmd_wdata;
  wire [32/8-1:0] nice_icb_cmd_wmask;
  wire [1:0] nice_icb_cmd_burst;
  wire [1:0] nice_icb_cmd_beat;
  wire [32-1:0] nice_icb_cmd_x_data;

  // Response channel from accelerator to CPU
  reg nice_icb_rsp_valid;
  wire nice_icb_rsp_ready;
  reg nice_icb_rsp_err;
  reg [32-1:0] nice_icb_rsp_rdata;

  // NICE instruction request/response
  wire nice_req_valid;
  reg nice_req_ready;
  wire [32-1:0] nice_req_inst;
  wire [32-1:0] nice_req_rs1;
  wire [32-1:0] nice_req_rs2;
  wire nice_req_mmode;

  reg nice_rsp_valid;
  wire nice_rsp_ready;
  reg [32-1:0] nice_rsp_rdata;
  reg nice_rsp_err;

  // External ITCM Interface (if enabled)
  `ifdef E203_HAS_ITCM_EXTITF
  reg ext2itcm_icb_cmd_valid;
  wire ext2itcm_icb_cmd_ready;
  reg [32-1:0] ext2itcm_icb_cmd_addr;
  reg ext2itcm_icb_cmd_read;
  reg [32-1:0] ext2itcm_icb_cmd_wdata;
  reg [32/8-1:0] ext2itcm_icb_cmd_wmask;
  wire ext2itcm_icb_rsp_valid;
  reg ext2itcm_icb_rsp_ready;
  wire ext2itcm_icb_rsp_err;
  wire [32-1:0] ext2itcm_icb_rsp_rdata;
  `endif

  // External DTCM Interface (if enabled)
  `ifdef E203_HAS_DTCM_EXTITF
  reg ext2dtcm_icb_cmd_valid;
  wire ext2dtcm_icb_cmd_ready;
  reg [32-1:0] ext2dtcm_icb_cmd_addr;
  reg ext2dtcm_icb_cmd_read;
  reg [32-1:0] ext2dtcm_icb_cmd_wdata;
  reg [32/8-1:0] ext2dtcm_icb_cmd_wmask;
  wire ext2dtcm_icb_rsp_valid;
  reg ext2dtcm_icb_rsp_ready;
  wire ext2dtcm_icb_rsp_err;
  wire [32-1:0] ext2dtcm_icb_rsp_rdata;
  `endif

  // System Memory Interface - CRITICAL for instruction/data access
  wire mem_icb_cmd_valid;
  reg mem_icb_cmd_ready;
  wire [32-1:0] mem_icb_cmd_addr;
  wire mem_icb_cmd_read;
  wire [32-1:0] mem_icb_cmd_wdata;
  wire [32/8-1:0] mem_icb_cmd_wmask;
  reg mem_icb_rsp_valid;
  wire mem_icb_rsp_ready;
  reg mem_icb_rsp_err;
  reg [32-1:0] mem_icb_rsp_rdata;

  // Peripheral Interfaces (can be stubbed for basic testing)
  wire ppi_icb_cmd_valid;
  reg ppi_icb_cmd_ready;
  wire [32-1:0] ppi_icb_cmd_addr;
  wire ppi_icb_cmd_read;
  wire [32-1:0] ppi_icb_cmd_wdata;
  wire [32/8-1:0] ppi_icb_cmd_wmask;
  reg ppi_icb_rsp_valid;
  wire ppi_icb_rsp_ready;
  reg ppi_icb_rsp_err;
  reg [32-1:0] ppi_icb_rsp_rdata;

  // CLINT Interface
  wire clint_icb_cmd_valid;
  reg clint_icb_cmd_ready;
  wire [32-1:0] clint_icb_cmd_addr;
  wire clint_icb_cmd_read;
  wire [32-1:0] clint_icb_cmd_wdata;
  wire [32/8-1:0] clint_icb_cmd_wmask;
  reg clint_icb_rsp_valid;
  wire clint_icb_rsp_ready;
  reg clint_icb_rsp_err;
  reg [32-1:0] clint_icb_rsp_rdata;

  // PLIC Interface
  wire plic_icb_cmd_valid;
  reg plic_icb_cmd_ready;
  wire [32-1:0] plic_icb_cmd_addr;
  wire plic_icb_cmd_read;
  wire [32-1:0] plic_icb_cmd_wdata;
  wire [32/8-1:0] plic_icb_cmd_wmask;
  reg plic_icb_rsp_valid;
  wire plic_icb_rsp_ready;
  reg plic_icb_rsp_err;
  reg [32-1:0] plic_icb_rsp_rdata;

  // Fast IO Interface
  wire fio_icb_cmd_valid;
  reg fio_icb_cmd_ready;
  wire [32-1:0] fio_icb_cmd_addr;
  wire fio_icb_cmd_read;
  wire [32-1:0] fio_icb_cmd_wdata;
  wire [32/8-1:0] fio_icb_cmd_wmask;
  reg fio_icb_rsp_valid;
  wire fio_icb_rsp_ready;
  reg fio_icb_rsp_err;
  reg [32-1:0] fio_icb_rsp_rdata;

  // Simple memory model for instruction/data storage
  reg [31:0] memory [0:4095]; // 16KB memory model
  reg [31:0] mem_read_data;
  reg mem_cmd_pending;
  reg [32-1:0] pending_addr;

  // PC tracking for monitoring
  reg [32-1:0] prev_pc;

  // NICE instruction tracking and accelerator simulation
  reg [31:0] nice_instruction_count;
  reg [31:0] nice_test_results [0:15]; // Store test results
  reg [3:0] nice_test_index;

  // Accelerator simulation registers
  reg [31:0] accel_data_buffer [0:255]; // Accelerator data buffer
  reg [7:0] accel_buffer_ptr;
  reg accel_busy;
  reg [3:0] accel_op_cycles; // Cycles to complete operation

  // Custom NICE instruction encodings
  parameter NICE_LOAD_DATA    = 7'b0001011; // Load data to accelerator
  parameter NICE_COMPUTE      = 7'b0001011; // Trigger computation
  parameter NICE_READ_RESULT  = 7'b0001011; // Read result from accelerator

  // NICE function codes
  parameter FUNC_ADD_ARRAY    = 3'b000; // Add two arrays
  parameter FUNC_MUL_ARRAY    = 3'b001; // Multiply two arrays
  parameter FUNC_DOT_PRODUCT  = 3'b010; // Dot product
  parameter FUNC_SQRT_ARRAY   = 3'b011; // Square root of array
  parameter FUNC_MATRIX_MUL   = 3'b100; // Matrix multiplication

  // DUT instantiation
  e203_cpu_top u_dut (
    .inspect_pc(inspect_pc),
    .inspect_dbg_irq(inspect_dbg_irq),
    .inspect_mem_cmd_valid(inspect_mem_cmd_valid),
    .inspect_mem_cmd_ready(inspect_mem_cmd_ready),
    .inspect_mem_rsp_valid(inspect_mem_rsp_valid),
    .inspect_mem_rsp_ready(inspect_mem_rsp_ready),
    .inspect_core_clk(inspect_core_clk),
    .core_csr_clk(core_csr_clk),
    .core_wfi(core_wfi),
    .tm_stop(tm_stop),
    .pc_rtvec(pc_rtvec),

    // Debug interface
    .dbg_irq_r(dbg_irq_r),
    .cmt_dpc(cmt_dpc),
    .cmt_dpc_ena(cmt_dpc_ena),
    .cmt_dcause(cmt_dcause),
    .cmt_dcause_ena(cmt_dcause_ena),
    .wr_dcsr_ena(wr_dcsr_ena),
    .wr_dpc_ena(wr_dpc_ena),
    .wr_dscratch_ena(wr_dscratch_ena),
    .wr_csr_nxt(wr_csr_nxt),
    .dcsr_r(dcsr_r),
    .dpc_r(dpc_r),
    .dscratch_r(dscratch_r),
    .dbg_mode(dbg_mode),
    .dbg_halt_r(dbg_halt_r),
    .dbg_step_r(dbg_step_r),
    .dbg_ebreakm_r(dbg_ebreakm_r),
    .dbg_stopcycle(dbg_stopcycle),
    .dbg_irq_a(dbg_irq_a),

    .core_mhartid(core_mhartid),
    .ext_irq_a(ext_irq_a),
    .sft_irq_a(sft_irq_a),
    .tmr_irq_a(tmr_irq_a),
    .tcm_sd(tcm_sd),
    .tcm_ds(tcm_ds),

    // NICE Interface
    // .nice_mem_holdup(nice_mem_holdup),
    // .nice_icb_cmd_valid(nice_icb_cmd_valid),
    // .nice_icb_cmd_ready(nice_icb_cmd_ready),
    // .nice_icb_cmd_addr(nice_icb_cmd_addr),
    // .nice_icb_cmd_read(nice_icb_cmd_read),
    // .nice_icb_cmd_wdata(nice_icb_cmd_wdata),
    // .nice_icb_cmd_wmask(nice_icb_cmd_wmask),
    // .nice_icb_cmd_burst(nice_icb_cmd_burst),
    // .nice_icb_cmd_beat(nice_icb_cmd_beat),
    // .nice_icb_cmd_x_data(nice_icb_cmd_x_data),
    // .nice_icb_rsp_valid(nice_icb_rsp_valid),
    // .nice_icb_rsp_ready(nice_icb_rsp_ready),
    // .nice_icb_rsp_err(nice_icb_rsp_err),
    // .nice_icb_rsp_rdata(nice_icb_rsp_rdata),
    
    // .nice_req_valid(nice_req_valid),
    // .nice_req_ready(nice_req_ready),
    // .nice_req_inst(nice_req_inst),
    // .nice_req_rs1(nice_req_rs1),
    // .nice_req_rs2(nice_req_rs2),
    // .nice_req_mmode(nice_req_mmode),
    // .nice_rsp_valid(nice_rsp_valid),
    // .nice_rsp_ready(nice_rsp_ready),
    // .nice_rsp_rdata(nice_rsp_rdata),
    // .nice_rsp_err(nice_rsp_err),

    `ifdef E203_HAS_ITCM_EXTITF
    .ext2itcm_icb_cmd_valid(ext2itcm_icb_cmd_valid),
    .ext2itcm_icb_cmd_ready(ext2itcm_icb_cmd_ready),
    .ext2itcm_icb_cmd_addr(ext2itcm_icb_cmd_addr),
    .ext2itcm_icb_cmd_read(ext2itcm_icb_cmd_read),
    .ext2itcm_icb_cmd_wdata(ext2itcm_icb_cmd_wdata),
    .ext2itcm_icb_cmd_wmask(ext2itcm_icb_cmd_wmask),
    .ext2itcm_icb_rsp_valid(ext2itcm_icb_rsp_valid),
    .ext2itcm_icb_rsp_ready(ext2itcm_icb_rsp_ready),
    .ext2itcm_icb_rsp_err(ext2itcm_icb_rsp_err),
    .ext2itcm_icb_rsp_rdata(ext2itcm_icb_rsp_rdata),
    `endif

    `ifdef E203_HAS_DTCM_EXTITF
    .ext2dtcm_icb_cmd_valid(ext2dtcm_icb_cmd_valid),
    .ext2dtcm_icb_cmd_ready(ext2dtcm_icb_cmd_ready),
    .ext2dtcm_icb_cmd_addr(ext2dtcm_icb_cmd_addr),
    .ext2dtcm_icb_cmd_read(ext2dtcm_icb_cmd_read),
    .ext2dtcm_icb_cmd_wdata(ext2dtcm_icb_cmd_wdata),
    .ext2dtcm_icb_cmd_wmask(ext2dtcm_icb_cmd_wmask),
    .ext2dtcm_icb_rsp_valid(ext2dtcm_icb_rsp_valid),
    .ext2dtcm_icb_rsp_ready(ext2dtcm_icb_rsp_ready),
    .ext2dtcm_icb_rsp_err(ext2dtcm_icb_rsp_err),
    .ext2dtcm_icb_rsp_rdata(ext2dtcm_icb_rsp_rdata),
    `endif

    // System Memory Interface
    .mem_icb_cmd_valid(mem_icb_cmd_valid),
    .mem_icb_cmd_ready(mem_icb_cmd_ready),
    .mem_icb_cmd_addr(mem_icb_cmd_addr),
    .mem_icb_cmd_read(mem_icb_cmd_read),
    .mem_icb_cmd_wdata(mem_icb_cmd_wdata),
    .mem_icb_cmd_wmask(mem_icb_cmd_wmask),
    .mem_icb_rsp_valid(mem_icb_rsp_valid),
    .mem_icb_rsp_ready(mem_icb_rsp_ready),
    .mem_icb_rsp_err(mem_icb_rsp_err),
    .mem_icb_rsp_rdata(mem_icb_rsp_rdata),

    // Peripheral interfaces
    .ppi_icb_cmd_valid(ppi_icb_cmd_valid),
    .ppi_icb_cmd_ready(ppi_icb_cmd_ready),
    .ppi_icb_cmd_addr(ppi_icb_cmd_addr),
    .ppi_icb_cmd_read(ppi_icb_cmd_read),
    .ppi_icb_cmd_wdata(ppi_icb_cmd_wdata),
    .ppi_icb_cmd_wmask(ppi_icb_cmd_wmask),
    .ppi_icb_rsp_valid(ppi_icb_rsp_valid),
    .ppi_icb_rsp_ready(ppi_icb_rsp_ready),
    .ppi_icb_rsp_err(ppi_icb_rsp_err),
    .ppi_icb_rsp_rdata(ppi_icb_rsp_rdata),

    .clint_icb_cmd_valid(clint_icb_cmd_valid),
    .clint_icb_cmd_ready(clint_icb_cmd_ready),
    .clint_icb_cmd_addr(clint_icb_cmd_addr),
    .clint_icb_cmd_read(clint_icb_cmd_read),
    .clint_icb_cmd_wdata(clint_icb_cmd_wdata),
    .clint_icb_cmd_wmask(clint_icb_cmd_wmask),
    .clint_icb_rsp_valid(clint_icb_rsp_valid),
    .clint_icb_rsp_ready(clint_icb_rsp_ready),
    .clint_icb_rsp_err(clint_icb_rsp_err),
    .clint_icb_rsp_rdata(clint_icb_rsp_rdata),

    .plic_icb_cmd_valid(plic_icb_cmd_valid),
    .plic_icb_cmd_ready(plic_icb_cmd_ready),
    .plic_icb_cmd_addr(plic_icb_cmd_addr),
    .plic_icb_cmd_read(plic_icb_cmd_read),
    .plic_icb_cmd_wdata(plic_icb_cmd_wdata),
    .plic_icb_cmd_wmask(plic_icb_cmd_wmask),
    .plic_icb_rsp_valid(plic_icb_rsp_valid),
    .plic_icb_rsp_ready(plic_icb_rsp_ready),
    .plic_icb_rsp_err(plic_icb_rsp_err),
    .plic_icb_rsp_rdata(plic_icb_rsp_rdata),

    .fio_icb_cmd_valid(fio_icb_cmd_valid),
    .fio_icb_cmd_ready(fio_icb_cmd_ready),
    .fio_icb_cmd_addr(fio_icb_cmd_addr),
    .fio_icb_cmd_read(fio_icb_cmd_read),
    .fio_icb_cmd_wdata(fio_icb_cmd_wdata),
    .fio_icb_cmd_wmask(fio_icb_cmd_wmask),
    .fio_icb_rsp_valid(fio_icb_rsp_valid),
    .fio_icb_rsp_ready(fio_icb_rsp_ready),
    .fio_icb_rsp_err(fio_icb_rsp_err),
    .fio_icb_rsp_rdata(fio_icb_rsp_rdata),

    .test_mode(test_mode),
    .clk(clk),
    .rst_n(rst_n)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
  end

  // Generate NICE instruction encoding function
  function [31:0] encode_nice_instruction(
    input [6:0] opcode, 
    input [4:0] rd, 
    input [4:0] rs1, 
    input [4:0] rs2, 
    input [2:0] funct3,
    input [6:0] funct7
  );
    encode_nice_instruction = {funct7, rs2, rs1, funct3, rd, opcode};
  endfunction

  // Initialize memory with comprehensive NICE instruction test program
  initial begin
    // Initialize test data arrays in memory (starting at address 0x1000)
    memory[1024] = 32'h00000001; // Array A[0] = 1
    memory[1025] = 32'h00000002; // Array A[1] = 2
    memory[1026] = 32'h00000003; // Array A[2] = 3
    memory[1027] = 32'h00000004; // Array A[3] = 4
    
    memory[1028] = 32'h00000005; // Array B[0] = 5
    memory[1029] = 32'h00000006; // Array B[1] = 6
    memory[1030] = 32'h00000007; // Array B[2] = 7
    memory[1031] = 32'h00000008; // Array B[3] = 8

    // Test program for NICE instructions
    memory[0] = 32'h10000537;   // lui x10, 0x10000   - Load base address for data
    memory[1] = 32'h00100093;   // addi x1, x0, 1     - Load test value 1
    memory[2] = 32'h00200113;   // addi x2, x0, 2     - Load test value 2
    memory[3] = 32'h00400193;   // addi x3, x0, 4     - Array length
    memory[4] = 32'h00050513;   // addi x10, x10, 0   - Array A base address
    memory[5] = 32'h01050593;   // addi x11, x10, 16  - Array B base address
    
    // NICE instruction: Load data to accelerator
    memory[6] = encode_nice_instruction(NICE_LOAD_DATA, 5'd0, 5'd10, 5'd3, 3'b010, 7'b0000001);
     memory[7] = encode_nice_instruction(NICE_LOAD_DATA, 5'd0, 5'd1, 5'd3, 3'b010, 7'b0000001);
      memory[8] = encode_nice_instruction(NICE_LOAD_DATA, 5'd0, 5'd2, 5'd3, 3'b010, 7'b0000001);
       memory[9] = encode_nice_instruction(NICE_LOAD_DATA, 5'd0, 5'd3, 5'd3, 3'b010, 7'b0000001);
    
    // NICE instruction: Trigger array addition computation
    memory[10] = encode_nice_instruction(NICE_COMPUTE, 5'd12, 5'd10, 5'd11, 3'b010, 7'b0000010);
    
    // NICE instruction: Read result
    memory[11] = encode_nice_instruction(NICE_READ_RESULT, 5'd13, 5'd11, 5'd0, 3'b010, 7'b0000011);
    
    
    
    memory[12] = 32'h00000013;  // nop
    memory[13] = 32'h0000006f;  // jal x0, 0 (infinite loop)
    
    // Initialize remaining memory with NOPs
    for (int i = 14; i < 1024; i++) begin
      memory[i] = 32'h00000013;
    end
    
    $display("Memory initialized with comprehensive NICE instruction test program");
    $display("Test data arrays loaded at addresses 0x1000-0x101F");
  end

 // System Memory Interface Model
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_icb_rsp_valid <= 1'b0;
      mem_icb_rsp_err <= 1'b0;
      mem_icb_rsp_rdata <= 32'h0;
      mem_cmd_pending <= 1'b0;
      pending_addr <= '0;
    end else begin
      // Handle command phase
      if (mem_icb_cmd_valid && mem_icb_cmd_ready && !mem_cmd_pending) begin
        mem_cmd_pending <= 1'b1;
        pending_addr <= mem_icb_cmd_addr;
        
        if (mem_icb_cmd_read) begin
          mem_read_data <= memory[mem_icb_cmd_addr[13:2]];
        end else begin
          if (mem_icb_cmd_wmask[0]) memory[mem_icb_cmd_addr[13:2]][7:0]   <= mem_icb_cmd_wdata[7:0];
          if (mem_icb_cmd_wmask[1]) memory[mem_icb_cmd_addr[13:2]][15:8]  <= mem_icb_cmd_wdata[15:8];
          if (mem_icb_cmd_wmask[2]) memory[mem_icb_cmd_addr[13:2]][23:16] <= mem_icb_cmd_wdata[23:16];
          if (mem_icb_cmd_wmask[3]) memory[mem_icb_cmd_addr[13:2]][31:24] <= mem_icb_cmd_wdata[31:24];
        end
      end

      if (mem_cmd_pending && !mem_icb_rsp_valid) begin
        mem_icb_rsp_valid <= 1'b1;
        mem_icb_rsp_err <= 1'b0;
        mem_icb_rsp_rdata <= mem_read_data;
      end

      if (mem_icb_rsp_valid && mem_icb_rsp_ready) begin
        mem_icb_rsp_valid <= 1'b0;
        mem_cmd_pending <= 1'b0;
      end
    end
  end

  assign mem_icb_cmd_ready = !mem_cmd_pending;

  // Stub peripheral interfaces
  assign ppi_icb_cmd_ready = 1'b0;
  assign clint_icb_cmd_ready = 1'b0;
  assign plic_icb_cmd_ready = 1'b0;
  assign fio_icb_cmd_ready = 1'b0;

  always @(*) begin
    ppi_icb_rsp_valid = 1'b0;
    ppi_icb_rsp_err = 1'b0;
    ppi_icb_rsp_rdata = 32'h0;
    
    clint_icb_rsp_valid = 1'b0;
    clint_icb_rsp_err = 1'b0;
    clint_icb_rsp_rdata = 32'h0;
    
    plic_icb_rsp_valid = 1'b0;
    plic_icb_rsp_err = 1'b0;
    plic_icb_rsp_rdata = 32'h0;
    
    fio_icb_rsp_valid = 1'b0;
    fio_icb_rsp_err = 1'b0;
    fio_icb_rsp_rdata = 32'h0;
  end

  // External TCM interfaces tie-offs
  `ifdef E203_HAS_ITCM_EXTITF
  initial begin
    ext2itcm_icb_cmd_valid = 1'b0;
    ext2itcm_icb_cmd_addr = '0;
    ext2itcm_icb_cmd_read = 1'b0;
    ext2itcm_icb_cmd_wdata = '0;
    ext2itcm_icb_cmd_wmask = '0;
    ext2itcm_icb_rsp_ready = 1'b1;
  end
  `endif

  `ifdef E203_HAS_DTCM_EXTITF
  initial begin
    ext2dtcm_icb_cmd_valid = 1'b0;
    ext2dtcm_icb_cmd_addr = '0;
    ext2dtcm_icb_cmd_read = 1'b0;
    ext2dtcm_icb_cmd_wdata = '0;
    ext2dtcm_icb_cmd_wmask = '0;
    ext2dtcm_icb_rsp_ready = 1'b1;
  end
  `endif

  // PC tracking block - FIXED to avoid $past issues
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_pc <= '0;
    end else begin
      prev_pc <= inspect_pc;
    end
  end

  // Test sequence
  initial begin
    // Initialize all inputs
    rst_n = 1'b0;
    test_mode = 1'b0;
    pc_rtvec = 32'h00000000; // Start execution from address 0
    
    // Debug interface - inactive
    dcsr_r = 32'h0;
    dpc_r = 32'h0;
    dscratch_r = 32'h0;
    dbg_mode = 1'b0;
    dbg_halt_r = 1'b0;
    dbg_step_r = 1'b0;
    dbg_ebreakm_r = 1'b0;
    dbg_stopcycle = 1'b0;
    dbg_irq_a = 1'b0;

    // Hart ID and interrupts
    core_mhartid = '0;
    ext_irq_a = 1'b0;
    sft_irq_a = 1'b0;
    tmr_irq_a = 1'b0;

    // TCM power management - normal operation
    tcm_sd = 1'b0;
    tcm_ds = 1'b0;

    // Wait for a few cycles then release reset
    repeat(10) @(posedge clk);
    rst_n = 1'b1;
    
    $display("Reset released at time %0t", $time);
    $display("PC reset vector: 0x%08x", pc_rtvec);

    // Monitor core activity
    fork
      begin
        // Monitor PC changes - FIXED VERSION
        forever begin
          @(posedge clk);
          if (rst_n && (inspect_pc !== prev_pc)) begin
            $display("Time %0t: PC changed from 0x%08x to 0x%08x", 
                     $time, prev_pc, inspect_pc);
          end
        end
      end
      
      begin
        // Monitor memory interface
        forever begin
          @(posedge clk);
          if (mem_icb_cmd_valid && mem_icb_cmd_ready) begin
            if (mem_icb_cmd_read) begin
              $display("Time %0t: Memory READ request - Addr: 0x%08x", 
                       $time, mem_icb_cmd_addr);
            end else begin
              $display("Time %0t: Memory WRITE request - Addr: 0x%08x, Data: 0x%08x, Mask: 0x%x", 
                       $time, mem_icb_cmd_addr, mem_icb_cmd_wdata, mem_icb_cmd_wmask);
            end
          end
          
          if (mem_icb_rsp_valid && mem_icb_rsp_ready) begin
            $display("Time %0t: Memory response - Data: 0x%08x, Error: %b", 
                     $time, mem_icb_rsp_rdata, mem_icb_rsp_err);
          end
        end
      end
    join_none

    // Run simulation
    repeat(1000) @(posedge clk);
    
    $display("\nSimulation Summary:");
    $display("Final PC: 0x%08x", inspect_pc);
    $display("Core WFI: %b", core_wfi);
    $display("Timer stop: %b", tm_stop);
    
    $finish;
  end

  // Timeout watchdog
  initial begin
    #100000; // 100us timeout
    $display("ERROR: Simulation timeout!");
    $finish;
  end

endmodule