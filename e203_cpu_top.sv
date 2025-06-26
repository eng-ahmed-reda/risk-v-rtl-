 `include "e203_defines.sv"

 /*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  The CPU-TOP module to implement CPU and SRAMs
//
// ====================================================================


module e203_cpu_top(
  input itcm_ls,
  input dtcm_ls,
  output itcm_ram_cs,
  output itcm_ram_we,
  output [16-1:0] itcm_ram_addr,
  output [8-1:0] itcm_ram_wem,
  output [64-1:0] itcm_ram_din,
  input [64-1:0] itcm_ram_dout,
  output dtcm_ram_cs,
  output dtcm_ram_we,
  output [16-1:0] dtcm_ram_addr,
  output [4-1:0] dtcm_ram_wem,
  output [32-1:0] dtcm_ram_din,
  input [32-1:0] dtcm_ram_dout,
  input rst_n,
  output [32-1:0] inspect_pc,
  output inspect_dbg_irq      ,
  output inspect_mem_cmd_valid,
  output inspect_mem_cmd_ready,
  output inspect_mem_rsp_valid,
  output inspect_mem_rsp_ready,
  output inspect_core_clk     ,

  output core_csr_clk         ,

    

    // If this signal is high, then indicate the Core have executed WFI instruction
    //   and entered into the sleep state
  output core_wfi,

    // This signal is from our self-defined COUNTERSTOP (0xBFF) CSR's TM field
    //   software can programe this CSR to turn off the MTIME timer to save power
    // If this signal is high, then the MTIME timer from CLINT module will stop counting
  output tm_stop,

    // This signal can be used to indicate the PC value for the core after reset
  input  [32-1:0] pc_rtvec,

  ///////////////////////////////////////
  // The interface to Debug Module: Begin
  //
    // The synced debug interrupt back to Debug module 
  output  dbg_irq_r,

    // The debug mode CSR registers control interface from/to Debug module
  output  [32-1:0] cmt_dpc,
  output  cmt_dpc_ena,
  output  [3-1:0] cmt_dcause,
  output  cmt_dcause_ena,
  output  wr_dcsr_ena    ,
  output  wr_dpc_ena     ,
  output  wr_dscratch_ena,
  output  [32-1:0] wr_csr_nxt    ,
  input  [32-1:0] dcsr_r    ,
  input  [32-1:0] dpc_r     ,
  input  [32-1:0] dscratch_r,

    // The debug mode control signals from Debug Module
  input  dbg_mode,
  input  dbg_halt_r,
  input  dbg_step_r,
  input  dbg_ebreakm_r,
  input  dbg_stopcycle,
  input  dbg_irq_a,
  // The interface to Debug Module: End


    // This signal can be used to indicate the HART ID for this core
  input  [1-1:0] core_mhartid,  

    // The External Interrupt signal from PLIC
  input  ext_irq_a,
    // The Software Interrupt signal from CLINT
  input  sft_irq_a,
    // The Timer Interrupt signal from CLINT
  input  tmr_irq_a,
  
  
    // The PMU control signal from PMU to control the TCM Shutdown
  input tcm_sd,
    // The PMU control signal from PMU to control the TCM Deep-Sleep
  input tcm_ds,
    
  //////////////////////////////////////////////////////////////
  // External interface (ICB) to access ITCM: Begin
  //    * Bus cmd channel
  input                          ext2itcm_icb_cmd_valid,
  output                         ext2itcm_icb_cmd_ready,
  input  [16-1:0]   ext2itcm_icb_cmd_addr, 
  input                          ext2itcm_icb_cmd_read, 
  input  [32-1:0]        ext2itcm_icb_cmd_wdata,
  input  [32/8-1:0]      ext2itcm_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  output                         ext2itcm_icb_rsp_valid,
  input                          ext2itcm_icb_rsp_ready,
  output                         ext2itcm_icb_rsp_err  ,
  output [32-1:0]        ext2itcm_icb_rsp_rdata,
  // External interface (ICB) to access ITCM: End

  //////////////////////////////////////////////////////////////
  // External interface (ICB) to access DTCM: Start
  //    * Bus cmd channel
  input                          ext2dtcm_icb_cmd_valid,
  output                         ext2dtcm_icb_cmd_ready,
  input  [16-1:0]   ext2dtcm_icb_cmd_addr, 
  input                          ext2dtcm_icb_cmd_read, 
  input  [32-1:0]        ext2dtcm_icb_cmd_wdata,
  input  [32/8-1:0]      ext2dtcm_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  output                         ext2dtcm_icb_rsp_valid,
  input                          ext2dtcm_icb_rsp_ready,
  output                         ext2dtcm_icb_rsp_err  ,
  output [32-1:0]        ext2dtcm_icb_rsp_rdata,
  // External interface (ICB) to access DTCM: End

  
  //////////////////////////////////////////////////////////////
  // The Private Peripheral Interface (ICB): Begin
  //
  //    * Bus cmd channel
  output                         ppi_icb_cmd_valid,
  input                          ppi_icb_cmd_ready,
  output [32-1:0]   ppi_icb_cmd_addr, 
  output                         ppi_icb_cmd_read, 
  output [32-1:0]        ppi_icb_cmd_wdata,
  output [32/8-1:0]      ppi_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          ppi_icb_rsp_valid,
  output                         ppi_icb_rsp_ready,
  input                          ppi_icb_rsp_err  ,
  input  [32-1:0]        ppi_icb_rsp_rdata,
  // The Private Peripheral Interface (ICB): End

  //////////////////////////////////////////////////////////////
  // The CLINT Interface (ICB): Begin
  output                         clint_icb_cmd_valid,
  input                          clint_icb_cmd_ready,
  output [32-1:0]   clint_icb_cmd_addr, 
  output                         clint_icb_cmd_read, 
  output [32-1:0]        clint_icb_cmd_wdata,
  output [32/8-1:0]      clint_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          clint_icb_rsp_valid,
  output                         clint_icb_rsp_ready,
  input                          clint_icb_rsp_err  ,
  input  [32-1:0]        clint_icb_rsp_rdata,
  // The CLINT Interface (ICB): End

  //////////////////////////////////////////////////////////////
  // The PLIC Interface (ICB): Begin
  output                         plic_icb_cmd_valid,
  input                          plic_icb_cmd_ready,
  output [32-1:0]   plic_icb_cmd_addr, 
  output                         plic_icb_cmd_read, 
  output [32-1:0]        plic_icb_cmd_wdata,
  output [32/8-1:0]      plic_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          plic_icb_rsp_valid,
  output                         plic_icb_rsp_ready,
  input                          plic_icb_rsp_err  ,
  input  [32-1:0]        plic_icb_rsp_rdata,
  // The PLIC Interface (ICB): End


  //////////////////////////////////////////////////////////////
  // The Fast IO Interface (ICB): Begin
  //
  //    * Bus cmd channel
  output                         fio_icb_cmd_valid,
  input                          fio_icb_cmd_ready,
  output [32-1:0]   fio_icb_cmd_addr, 
  output                         fio_icb_cmd_read, 
  output [32-1:0]        fio_icb_cmd_wdata,
  output [32/8-1:0]      fio_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          fio_icb_rsp_valid,
  output                         fio_icb_rsp_ready,
  input                          fio_icb_rsp_err  ,
  input  [32-1:0]        fio_icb_rsp_rdata,
  // The Fast IO Interface (ICB): End

  //////////////////////////////////////////////////////////////

  // The test mode signal
  input  test_mode,

  // The Clock
  input  clk,

  // JTAG Ports
  input  wire                         jtag_tck,
  input  wire                         jtag_tms,
  input  wire                         jtag_tdi,
  input  wire                         jtag_tdo_i,
  output wire                         jtag_tdo_o,
  output wire                         jtag_tdo_oe,

  // External Memory Interface for Boot ROM
  output wire                         mem_icb_cmd_valid,
  input  wire                         mem_icb_cmd_ready,
  output wire [31:0]                  mem_icb_cmd_addr,
  output wire                         mem_icb_cmd_read,
  output wire [31:0]                  mem_icb_cmd_wdata,
  output wire [3:0]                   mem_icb_cmd_wmask,
  input  wire                         mem_icb_rsp_valid,
  output wire                         mem_icb_rsp_ready,
  input  wire                         mem_icb_rsp_err,
  input  wire [31:0]                  mem_icb_rsp_rdata,

  input  wire [31:0]                  boot_addr

  );

  wire rst_itcm;

  wire                          clk_dtcm_ram ;

  wire ppi_icb_rsp_excl_ok   ;
  wire fio_icb_rsp_excl_ok   ;
  wire plic_icb_rsp_excl_ok  ;
  wire clint_icb_rsp_excl_ok ;
  wire mem_icb_rsp_excl_ok   ;

  wire ppi_icb_enable;
  wire [32-1:0] ppi_region_indic;

  wire plic_icb_enable;
  wire [32-1:0] plic_region_indic;

  wire clint_icb_enable;
  wire [32-1:0] clint_region_indic;

  wire mem_icb_enable;

  wire fio_icb_enable;
  wire [32-1:0] fio_region_indic;

    assign ppi_icb_rsp_excl_ok   = 1'b0;
    assign fio_icb_rsp_excl_ok   = 1'b0;
    assign plic_icb_rsp_excl_ok  = 1'b0;
    assign clint_icb_rsp_excl_ok = 1'b0;
    assign mem_icb_rsp_excl_ok   = 1'b0;

    assign ppi_icb_enable = 1'b1;
    assign ppi_region_indic = `E203_PPI_ADDR_BASE;

    assign plic_icb_enable = 1'b1;
    assign plic_region_indic = `E203_PLIC_ADDR_BASE;

    assign clint_icb_enable = 1'b1;
    assign clint_region_indic = `E203_CLINT_ADDR_BASE;

    assign mem_icb_enable = 1'b1;

    assign fio_icb_enable = 1'b1;
    assign fio_region_indic = `E203_FIO_ADDR_BASE;

  e203_cpu #(.MASTER(1)) u_e203_cpu(
    .inspect_pc               (inspect_pc), 
    .inspect_dbg_irq          (inspect_dbg_irq      ),
    .inspect_mem_cmd_valid    (inspect_mem_cmd_valid), 
    .inspect_mem_cmd_ready    (inspect_mem_cmd_ready), 
    .inspect_mem_rsp_valid    (inspect_mem_rsp_valid),
    .inspect_mem_rsp_ready    (inspect_mem_rsp_ready),
    .inspect_core_clk         (inspect_core_clk     ),


    .core_csr_clk          (core_csr_clk      ),


    .tm_stop (tm_stop),
    .pc_rtvec(pc_rtvec),
    .itcm_ls (itcm_ls),
    .dtcm_ls (dtcm_ls),
    .core_wfi        (core_wfi),
    .dbg_irq_r       (dbg_irq_r      ),

    .cmt_dpc         (cmt_dpc        ),
    .cmt_dpc_ena     (cmt_dpc_ena    ),
    .cmt_dcause      (cmt_dcause     ),
    .cmt_dcause_ena  (cmt_dcause_ena ),

    .wr_dcsr_ena     (wr_dcsr_ena    ),
    .wr_dpc_ena      (wr_dpc_ena     ),
    .wr_dscratch_ena (wr_dscratch_ena),


                                     
    .wr_csr_nxt      (wr_csr_nxt    ),
                                     
    .dcsr_r          (dcsr_r         ),
    .dpc_r           (dpc_r          ),
    .dscratch_r      (dscratch_r     ),

    .dbg_mode        (dbg_mode),
    .dbg_halt_r      (dbg_halt_r),
    .dbg_step_r      (dbg_step_r),
    .dbg_ebreakm_r   (dbg_ebreakm_r),
    .dbg_stopcycle   (dbg_stopcycle),

    .core_mhartid    (core_mhartid),  
    .dbg_irq_a       (dbg_irq_a),
    .ext_irq_a       (ext_irq_a),
    .sft_irq_a       (sft_irq_a),
    .tmr_irq_a       (tmr_irq_a),

    .ext2itcm_icb_cmd_valid  (ext2itcm_icb_cmd_valid),
    .ext2itcm_icb_cmd_ready  (ext2itcm_icb_cmd_ready),
    .ext2itcm_icb_cmd_addr   (ext2itcm_icb_cmd_addr ),
    .ext2itcm_icb_cmd_read   (ext2itcm_icb_cmd_read ),
    .ext2itcm_icb_cmd_wdata  (ext2itcm_icb_cmd_wdata),
    .ext2itcm_icb_cmd_wmask  (ext2itcm_icb_cmd_wmask),
    
    .ext2itcm_icb_rsp_valid  (ext2itcm_icb_rsp_valid),
    .ext2itcm_icb_rsp_ready  (ext2itcm_icb_rsp_ready),
    .ext2itcm_icb_rsp_err    (ext2itcm_icb_rsp_err  ),
    .ext2itcm_icb_rsp_rdata  (ext2itcm_icb_rsp_rdata),

    .ext2dtcm_icb_cmd_valid  (ext2dtcm_icb_cmd_valid),
    .ext2dtcm_icb_cmd_ready  (ext2dtcm_icb_cmd_ready),
    .ext2dtcm_icb_cmd_addr   (ext2dtcm_icb_cmd_addr ),
    .ext2dtcm_icb_cmd_read   (ext2dtcm_icb_cmd_read ),
    .ext2dtcm_icb_cmd_wdata  (ext2dtcm_icb_cmd_wdata),
    .ext2dtcm_icb_cmd_wmask  (ext2dtcm_icb_cmd_wmask),
    
    .ext2dtcm_icb_rsp_valid  (ext2dtcm_icb_rsp_valid),
    .ext2dtcm_icb_rsp_ready  (ext2dtcm_icb_rsp_ready),
    .ext2dtcm_icb_rsp_err    (ext2dtcm_icb_rsp_err  ),
    .ext2dtcm_icb_rsp_rdata  (ext2dtcm_icb_rsp_rdata),


    .ppi_region_indic      (ppi_region_indic),
    .ppi_icb_enable        (ppi_icb_enable),
    .ppi_icb_cmd_valid     (ppi_icb_cmd_valid),
    .ppi_icb_cmd_ready     (ppi_icb_cmd_ready),
    .ppi_icb_cmd_addr      (ppi_icb_cmd_addr ),
    .ppi_icb_cmd_read      (ppi_icb_cmd_read ),
    .ppi_icb_cmd_wdata     (ppi_icb_cmd_wdata),
    .ppi_icb_cmd_wmask     (ppi_icb_cmd_wmask),
    .ppi_icb_cmd_lock      (),
    .ppi_icb_cmd_excl      (),
    .ppi_icb_cmd_size      (),
    
    .ppi_icb_rsp_valid     (ppi_icb_rsp_valid),
    .ppi_icb_rsp_ready     (ppi_icb_rsp_ready),
    .ppi_icb_rsp_err       (ppi_icb_rsp_err  ),
    .ppi_icb_rsp_excl_ok   (ppi_icb_rsp_excl_ok  ),
    .ppi_icb_rsp_rdata     (ppi_icb_rsp_rdata),

    .clint_region_indic      (clint_region_indic),
    .clint_icb_enable        (clint_icb_enable),
    .clint_icb_cmd_valid     (clint_icb_cmd_valid),
    .clint_icb_cmd_ready     (clint_icb_cmd_ready),
    .clint_icb_cmd_addr      (clint_icb_cmd_addr ),
    .clint_icb_cmd_read      (clint_icb_cmd_read ),
    .clint_icb_cmd_wdata     (clint_icb_cmd_wdata),
    .clint_icb_cmd_wmask     (clint_icb_cmd_wmask),
    .clint_icb_cmd_lock      (),
    .clint_icb_cmd_excl      (),
    .clint_icb_cmd_size      (),
    
    .clint_icb_rsp_valid     (clint_icb_rsp_valid),
    .clint_icb_rsp_ready     (clint_icb_rsp_ready),
    .clint_icb_rsp_err       (clint_icb_rsp_err  ),
    .clint_icb_rsp_excl_ok   (clint_icb_rsp_excl_ok  ),
    .clint_icb_rsp_rdata     (clint_icb_rsp_rdata),

    .plic_region_indic      (plic_region_indic),
    .plic_icb_enable        (plic_icb_enable),
    .plic_icb_cmd_valid     (plic_icb_cmd_valid),
    .plic_icb_cmd_ready     (plic_icb_cmd_ready),
    .plic_icb_cmd_addr      (plic_icb_cmd_addr ),
    .plic_icb_cmd_read      (plic_icb_cmd_read ),
    .plic_icb_cmd_wdata     (plic_icb_cmd_wdata),
    .plic_icb_cmd_wmask     (plic_icb_cmd_wmask),
    .plic_icb_cmd_lock      (),
    .plic_icb_cmd_excl      (),
    .plic_icb_cmd_size      (),
    
    .plic_icb_rsp_valid     (plic_icb_rsp_valid),
    .plic_icb_rsp_ready     (plic_icb_rsp_ready),
    .plic_icb_rsp_err       (plic_icb_rsp_err  ),
    .plic_icb_rsp_excl_ok   (plic_icb_rsp_excl_ok  ),
    .plic_icb_rsp_rdata     (plic_icb_rsp_rdata),


    .fio_icb_enable        (fio_icb_enable),
    .fio_region_indic      (fio_region_indic),
    .fio_icb_cmd_valid     (fio_icb_cmd_valid),
    .fio_icb_cmd_ready     (fio_icb_cmd_ready),
    .fio_icb_cmd_addr      (fio_icb_cmd_addr ),
    .fio_icb_cmd_read      (fio_icb_cmd_read ),
    .fio_icb_cmd_wdata     (fio_icb_cmd_wdata),
    .fio_icb_cmd_wmask     (fio_icb_cmd_wmask),
    .fio_icb_cmd_lock      (),
    .fio_icb_cmd_excl      (),
    .fio_icb_cmd_size      (),
    
    .fio_icb_rsp_valid     (fio_icb_rsp_valid),
    .fio_icb_rsp_ready     (fio_icb_rsp_ready),
    .fio_icb_rsp_err       (fio_icb_rsp_err  ),
    .fio_icb_rsp_excl_ok   (fio_icb_rsp_excl_ok  ),
    .fio_icb_rsp_rdata     (fio_icb_rsp_rdata),

    .mem_icb_enable     (mem_icb_enable),
    .mem_icb_cmd_valid  (mem_icb_cmd_valid),
    .mem_icb_cmd_ready  (mem_icb_cmd_ready),
    .mem_icb_cmd_addr   (mem_icb_cmd_addr ),
    .mem_icb_cmd_read   (mem_icb_cmd_read ),
    .mem_icb_cmd_wdata  (mem_icb_cmd_wdata),
    .mem_icb_cmd_wmask  (mem_icb_cmd_wmask),
    .mem_icb_cmd_lock   (),
    .mem_icb_cmd_excl   (),
    .mem_icb_cmd_size   (),
    .mem_icb_cmd_burst  (),
    .mem_icb_cmd_beat   (),
    
    .mem_icb_rsp_valid  (mem_icb_rsp_valid),
    .mem_icb_rsp_ready  (mem_icb_rsp_ready),
    .mem_icb_rsp_err    (mem_icb_rsp_err  ),
    .mem_icb_rsp_excl_ok(mem_icb_rsp_excl_ok  ),
    .mem_icb_rsp_rdata  (mem_icb_rsp_rdata),

    .itcm_ram_cs   (itcm_ram_cs  ),
    .itcm_ram_we   (itcm_ram_we  ),
    .itcm_ram_addr (itcm_ram_addr), 
    .itcm_ram_wem  (itcm_ram_wem ),
    .itcm_ram_din  (itcm_ram_din ),         
    .itcm_ram_dout (itcm_ram_dout),
    .clk_itcm_ram  (clk_itcm_ram ),  
    .rst_itcm(rst_itcm),

    .dtcm_ram_cs   (dtcm_ram_cs  ),
    .dtcm_ram_we   (dtcm_ram_we  ),
    .dtcm_ram_addr (dtcm_ram_addr), 
    .dtcm_ram_wem  (dtcm_ram_wem ),
    .dtcm_ram_din  (dtcm_ram_din ),         
    .dtcm_ram_dout (dtcm_ram_dout),
    .clk_dtcm_ram  (clk_dtcm_ram ),  
    .rst_dtcm(rst_dtcm),

    .test_mode     (test_mode), 
    .rst_n         (rst_n),
    .clk           (clk  ),

    .jtag_tck(jtag_tck),
    .jtag_tms(jtag_tms),
    .jtag_tdi(jtag_tdi),
    .jtag_tdo_i(jtag_tdo_i),
    .jtag_tdo_o(jtag_tdo_o),
    .jtag_tdo_oe(jtag_tdo_oe),

    .boot_addr(boot_addr)
  );

  e203_srams u_e203_srams(
   .dtcm_ram_sd (tcm_sd),
   .dtcm_ram_ds (tcm_ds),
   .dtcm_ram_ls (dtcm_ls),

   .dtcm_ram_cs   (dtcm_ram_cs  ),
   .dtcm_ram_we   (dtcm_ram_we  ),
   .dtcm_ram_addr (dtcm_ram_addr), 
   .dtcm_ram_wem  (dtcm_ram_wem ),
   .dtcm_ram_din  (dtcm_ram_din ),         
   .dtcm_ram_dout (dtcm_ram_dout),
   .clk_dtcm_ram  (clk_dtcm_ram ),  
   .rst_dtcm(rst_dtcm),

   .itcm_ram_sd (tcm_sd),
   .itcm_ram_ds (tcm_ds),
   .itcm_ram_ls (itcm_ls),

   .itcm_ram_cs   (itcm_ram_cs  ),
   .itcm_ram_we   (itcm_ram_we  ),
   .itcm_ram_addr (itcm_ram_addr), 
   .itcm_ram_wem  (itcm_ram_wem ),
   .itcm_ram_din  (itcm_ram_din ),         
   .itcm_ram_dout (itcm_ram_dout),
   .clk_itcm_ram  (clk_itcm_ram ),  
   .rst_itcm(rst_itcm),
   .test_mode (test_mode) 
  );

  


endmodule
