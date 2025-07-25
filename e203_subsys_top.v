// Fixed version of e203_subsys_top.v
// Replace the conditional interface signals with direct connections

module e203_subsys_top(
  // This clock should comes from the crystal pad generated high speed clock (16MHz)
  input  hfextclk,
  output hfxoscen,// The signal to enable the crystal pad generated clock

  // This clock should comes from the crystal pad generated low speed clock (32.768KHz)
  input  lfextclk,
  output lfxoscen,// The signal to enable the crystal pad generated clock

  input  io_pads_dbgmode0_n_i_ival,
  input  io_pads_dbgmode1_n_i_ival,
  input  io_pads_dbgmode2_n_i_ival,

  input  io_pads_bootrom_n_i_ival,
  output io_pads_bootrom_n_o_oval,
  output io_pads_bootrom_n_o_oe,
  output io_pads_bootrom_n_o_ie,
  output io_pads_bootrom_n_o_pue,
  output io_pads_bootrom_n_o_ds,

  input  io_pads_aon_erst_n_i_ival,
  output io_pads_aon_erst_n_o_oval,
  output io_pads_aon_erst_n_o_oe,
  output io_pads_aon_erst_n_o_ie,
  output io_pads_aon_erst_n_o_pue,
  output io_pads_aon_erst_n_o_ds,

  input  io_pads_aon_pmu_dwakeup_n_i_ival,
  output io_pads_aon_pmu_dwakeup_n_o_oval,
  output io_pads_aon_pmu_dwakeup_n_o_oe,
  output io_pads_aon_pmu_dwakeup_n_o_ie,
  output io_pads_aon_pmu_dwakeup_n_o_pue,
  output io_pads_aon_pmu_dwakeup_n_o_ds,
  input  io_pads_aon_pmu_vddpaden_i_ival,
  output io_pads_aon_pmu_vddpaden_o_oval,
  output io_pads_aon_pmu_vddpaden_o_oe,
  output io_pads_aon_pmu_vddpaden_o_ie,
  output io_pads_aon_pmu_vddpaden_o_pue,
  output io_pads_aon_pmu_vddpaden_o_ds,
  input  io_pads_aon_pmu_padrst_i_ival,
  output io_pads_aon_pmu_padrst_o_oval,
  output io_pads_aon_pmu_padrst_o_oe,
  output io_pads_aon_pmu_padrst_o_ie,
  output io_pads_aon_pmu_padrst_o_pue,
  output io_pads_aon_pmu_padrst_o_ds,

  input  core_mhartid,  
    
  // ITCM External Interface - ALWAYS PRESENT since E203_HAS_ITCM_EXTITF is defined
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // External-agent ICB to ITCM
  //    * Bus cmd channel
  input                          ext2itcm_icb_cmd_valid,
  output                         ext2itcm_icb_cmd_ready,
  input  [15:0]   ext2itcm_icb_cmd_addr, 
  input                          ext2itcm_icb_cmd_read, 
  input  [31:0]        ext2itcm_icb_cmd_wdata,
  input  [32/8-1:0]      ext2itcm_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  output                         ext2itcm_icb_rsp_valid,
  input                          ext2itcm_icb_rsp_ready,
  output                         ext2itcm_icb_rsp_err  ,
  output [31:0]        ext2itcm_icb_rsp_rdata,

  // DTCM External Interface - ALWAYS PRESENT since E203_HAS_DTCM_EXTITF is defined
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // External-agent ICB to DTCM
  //    * Bus cmd channel
  input                          ext2dtcm_icb_cmd_valid,
  output                         ext2dtcm_icb_cmd_ready,
  input  [15:0]   ext2dtcm_icb_cmd_addr, 
  input                          ext2dtcm_icb_cmd_read, 
  input  [31:0]        ext2dtcm_icb_cmd_wdata,
  input  [32/8-1:0]      ext2dtcm_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  output                         ext2dtcm_icb_rsp_valid,
  input                          ext2dtcm_icb_rsp_ready,
  output                         ext2dtcm_icb_rsp_err  ,
  output [31:0]        ext2dtcm_icb_rsp_rdata,

  
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface to Private Peripheral Interface
  //
  //    * Bus cmd channel
  output                         sysper_icb_cmd_valid,
  input                          sysper_icb_cmd_ready,
  output [31:0]   sysper_icb_cmd_addr, 
  output                         sysper_icb_cmd_read, 
  output [31:0]        sysper_icb_cmd_wdata,
  output [32/8-1:0]      sysper_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          sysper_icb_rsp_valid,
  output                         sysper_icb_rsp_ready,
  input                          sysper_icb_rsp_err  ,
  input  [31:0]        sysper_icb_rsp_rdata,

  // Fast I/O Interface - ALWAYS PRESENT since E203_HAS_FIO is defined
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface to Fast I/O
  //
  //    * Bus cmd channel
  output                         sysfio_icb_cmd_valid,
  input                          sysfio_icb_cmd_ready,
  output [31:0]   sysfio_icb_cmd_addr, 
  output                         sysfio_icb_cmd_read, 
  output [31:0]        sysfio_icb_cmd_wdata,
  output [32/8-1:0]      sysfio_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          sysfio_icb_rsp_valid,
  output                         sysfio_icb_rsp_ready,
  input                          sysfio_icb_rsp_err  ,
  input  [31:0]        sysfio_icb_rsp_rdata,

  // Memory Interface - ALWAYS PRESENT since E203_HAS_MEM_ITF is defined
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The ICB Interface from Ifetch 
  //
  //    * Bus cmd channel
  output                         sysmem_icb_cmd_valid,
  input                          sysmem_icb_cmd_ready,
  output [31:0]   sysmem_icb_cmd_addr, 
  output                         sysmem_icb_cmd_read, 
  output [31:0]        sysmem_icb_cmd_wdata,
  output [32/8-1:0]      sysmem_icb_cmd_wmask,
  //
  //    * Bus RSP channel
  input                          sysmem_icb_rsp_valid,
  output                         sysmem_icb_rsp_ready,
  input                          sysmem_icb_rsp_err  ,
  input  [31:0]        sysmem_icb_rsp_rdata,

  input  [32-1:0] io_pads_gpioA_i_ival,
  output [32-1:0] io_pads_gpioA_o_oval,
  output [32-1:0] io_pads_gpioA_o_oe,

  input  [32-1:0] io_pads_gpioB_i_ival,
  output [32-1:0] io_pads_gpioB_o_oval,
  output [32-1:0] io_pads_gpioB_o_oe,

  input   io_pads_qspi0_sck_i_ival,
  output  io_pads_qspi0_sck_o_oval,
  output  io_pads_qspi0_sck_o_oe,
  input   io_pads_qspi0_dq_0_i_ival,
  output  io_pads_qspi0_dq_0_o_oval,
  output  io_pads_qspi0_dq_0_o_oe,
  input   io_pads_qspi0_dq_1_i_ival,
  output  io_pads_qspi0_dq_1_o_oval,
  output  io_pads_qspi0_dq_1_o_oe,
  input   io_pads_qspi0_dq_2_i_ival,
  output  io_pads_qspi0_dq_2_o_oval,
  output  io_pads_qspi0_dq_2_o_oe,
  input   io_pads_qspi0_dq_3_i_ival,
  output  io_pads_qspi0_dq_3_o_oval,
  output  io_pads_qspi0_dq_3_o_oe,
  input   io_pads_qspi0_cs_0_i_ival,
  output  io_pads_qspi0_cs_0_o_oval,
  output  io_pads_qspi0_cs_0_o_oe,

  input   io_pads_jtag_TCK_i_ival,
  output  io_pads_jtag_TCK_o_oval,
  output  io_pads_jtag_TCK_o_oe,
  output  io_pads_jtag_TCK_o_ie,
  output  io_pads_jtag_TCK_o_pue,
  output  io_pads_jtag_TCK_o_ds,
  input   io_pads_jtag_TMS_i_ival,
  output  io_pads_jtag_TMS_o_oval,
  output  io_pads_jtag_TMS_o_oe,
  output  io_pads_jtag_TMS_o_ie,
  output  io_pads_jtag_TMS_o_pue,
  output  io_pads_jtag_TMS_o_ds,
  input   io_pads_jtag_TDI_i_ival,
  output  io_pads_jtag_TDI_o_oval,
  output  io_pads_jtag_TDI_o_oe,
  output  io_pads_jtag_TDI_o_ie,
  output  io_pads_jtag_TDI_o_pue,
  output  io_pads_jtag_TDI_o_ds,
  input   io_pads_jtag_TDO_i_ival,
  output  io_pads_jtag_TDO_o_oval,
  output  io_pads_jtag_TDO_o_oe,
  output  io_pads_jtag_TDO_o_ie,
  output  io_pads_jtag_TDO_o_pue,
  output  io_pads_jtag_TDO_o_ds,
  input   io_pads_jtag_TRST_n_i_ival,
  output  io_pads_jtag_TRST_n_o_oval,
  output  io_pads_jtag_TRST_n_o_oe,
  output  io_pads_jtag_TRST_n_o_ie,
  output  io_pads_jtag_TRST_n_o_pue,
  output  io_pads_jtag_TRST_n_o_ds,

  input  test_iso_override,
  input  test_mode,

  // JTAG
  output wire                         jtag_tck,
  output wire                         jtag_tms,
  output wire                         jtag_tdi,
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

  // AON
  input  wire                         aon_erst_n,
  input  wire                         bootrom_n
  );

  wire hfclk;// The PLL generated high-speed clock 
  wire hfclkrst;// The reset signal to disable PLL
  wire corerst;

  ///////////////////////////////////////
  wire dbg_irq;

  wire  [31:0] cmt_dpc;
  wire  cmt_dpc_ena;

  wire  [3-1:0] cmt_dcause;
  wire  cmt_dcause_ena;

  wire  dbg_irq_r;

  wire  wr_dcsr_ena;
  wire  wr_dpc_ena ;
  wire  wr_dscratch_ena;

  wire  [32-1:0] wr_csr_nxt;

  wire  [32-1:0] dcsr_r    ;
  wire  [31:0] dpc_r     ;
  wire  [32-1:0] dscratch_r;

  wire  dbg_mode;
  wire  dbg_halt_r;
  wire  dbg_step_r;
  wire  dbg_ebreakm_r;
  wire  dbg_stopcycle;

  wire  inspect_mode; 
  wire  inspect_por_rst; 
  wire  inspect_32k_clk; 
  wire  inspect_pc_29b; 
  wire  inspect_dbg_irq;
  wire  inspect_jtag_clk;
  wire  core_csr_clk;

  wire                          dm_icb_cmd_valid;
  wire                          dm_icb_cmd_ready;
  wire  [31:0]   dm_icb_cmd_addr; 
  wire                          dm_icb_cmd_read; 
  wire  [31:0]        dm_icb_cmd_wdata;
  //
  wire                          dm_icb_rsp_valid;
  wire                          dm_icb_rsp_ready;
  wire  [31:0]        dm_icb_rsp_rdata;

  wire  aon_wdg_irq_a   ;
  wire  aon_rtc_irq_a   ;
  wire  aon_rtcToggle_a ;

  wire                          aon_icb_cmd_valid;
  wire                          aon_icb_cmd_ready;
  wire  [31:0]   aon_icb_cmd_addr; 
  wire                          aon_icb_cmd_read; 
  wire  [31:0]        aon_icb_cmd_wdata;
  //
  wire                          aon_icb_rsp_valid;
  wire                          aon_icb_rsp_ready;
  wire  [31:0]        aon_icb_rsp_rdata;

  wire  [31:0] pc_rtvec;

  //═══════════════════════════════════════════════════════════════════
  // FIXED SUBSYS_MAIN INSTANTIATION - ALL INTERFACES ALWAYS PRESENT
  //═══════════════════════════════════════════════════════════════════

  e203_subsys_main  u_e203_subsys_main(
    .pc_rtvec        (pc_rtvec),

    .inspect_mode    (inspect_mode    ), 
    .inspect_por_rst (inspect_por_rst), 
    .inspect_32k_clk (inspect_32k_clk), 
    .inspect_pc_29b  (inspect_pc_29b  ), 
    .inspect_dbg_irq (inspect_dbg_irq ),
    .inspect_jtag_clk(inspect_jtag_clk),
    .core_csr_clk    (core_csr_clk    ),

    .hfextclk        (hfextclk),
    .hfxoscen        (hfxoscen),

    .dbg_irq_r       (dbg_irq_r      ),

    .cmt_dpc         (cmt_dpc        ),
    .cmt_dpc_ena     (cmt_dpc_ena    ),
    .cmt_dcause      (cmt_dcause     ),
    .cmt_dcause_ena  (cmt_dcause_ena ),

    .wr_dcsr_ena     (wr_dcsr_ena    ),
    .wr_dpc_ena      (wr_dpc_ena     ),
    .wr_dscratch_ena (wr_dscratch_ena),
                                     
    .wr_csr_nxt      (wr_csr_nxt     ),

    .dcsr_r          (dcsr_r         ),
    .dpc_r           (dpc_r          ),
    .dscratch_r      (dscratch_r     ),

    .dbg_mode        (dbg_mode),
    .dbg_halt_r      (dbg_halt_r),
    .dbg_step_r      (dbg_step_r),
    .dbg_ebreakm_r   (dbg_ebreakm_r),
    .dbg_stopcycle   (dbg_stopcycle),

    .core_mhartid            (core_mhartid),  
    .dbg_irq_a               (dbg_irq),
    
    .aon_wdg_irq_a           (aon_wdg_irq_a     ),      
    .aon_rtc_irq_a           (aon_rtc_irq_a     ),
    .aon_rtcToggle_a         (aon_rtcToggle_a   ),
                             
    .aon_icb_cmd_valid       (aon_icb_cmd_valid ),
    .aon_icb_cmd_ready       (aon_icb_cmd_ready ),
    .aon_icb_cmd_addr        (aon_icb_cmd_addr  ),
    .aon_icb_cmd_read        (aon_icb_cmd_read  ),
    .aon_icb_cmd_wdata       (aon_icb_cmd_wdata ),
                            
    .aon_icb_rsp_valid       (aon_icb_rsp_valid ),
    .aon_icb_rsp_ready       (aon_icb_rsp_ready ),
    .aon_icb_rsp_err         (1'b0   ),
    .aon_icb_rsp_rdata       (aon_icb_rsp_rdata ),

    .dm_icb_cmd_valid         (dm_icb_cmd_valid),
    .dm_icb_cmd_ready         (dm_icb_cmd_ready),
    .dm_icb_cmd_addr          (dm_icb_cmd_addr ),
    .dm_icb_cmd_read          (dm_icb_cmd_read ),
    .dm_icb_cmd_wdata         (dm_icb_cmd_wdata),
    
    .dm_icb_rsp_valid         (dm_icb_rsp_valid),
    .dm_icb_rsp_ready         (dm_icb_rsp_ready),
    .dm_icb_rsp_rdata         (dm_icb_rsp_rdata),

    .io_pads_gpioA_i_ival       (io_pads_gpioA_i_ival),
    .io_pads_gpioA_o_oval       (io_pads_gpioA_o_oval),
    .io_pads_gpioA_o_oe         (io_pads_gpioA_o_oe), 

    .io_pads_gpioB_i_ival       (io_pads_gpioB_i_ival),
    .io_pads_gpioB_o_oval       (io_pads_gpioB_o_oval),
    .io_pads_gpioB_o_oe         (io_pads_gpioB_o_oe),

    .io_pads_qspi0_sck_i_ival   (io_pads_qspi0_sck_i_ival),
    .io_pads_qspi0_sck_o_oval   (io_pads_qspi0_sck_o_oval),
    .io_pads_qspi0_sck_o_oe     (io_pads_qspi0_sck_o_oe),
    .io_pads_qspi0_dq_0_i_ival  (io_pads_qspi0_dq_0_i_ival),
    .io_pads_qspi0_dq_0_o_oval  (io_pads_qspi0_dq_0_o_oval),
    .io_pads_qspi0_dq_0_o_oe    (io_pads_qspi0_dq_0_o_oe),
    .io_pads_qspi0_dq_1_i_ival  (io_pads_qspi0_dq_1_i_ival),
    .io_pads_qspi0_dq_1_o_oval  (io_pads_qspi0_dq_1_o_oval),
    .io_pads_qspi0_dq_1_o_oe    (io_pads_qspi0_dq_1_o_oe),
    .io_pads_qspi0_dq_2_i_ival  (io_pads_qspi0_dq_2_i_ival),
    .io_pads_qspi0_dq_2_o_oval  (io_pads_qspi0_dq_2_o_oval),
    .io_pads_qspi0_dq_2_o_oe    (io_pads_qspi0_dq_2_o_oe),
    .io_pads_qspi0_dq_3_i_ival  (io_pads_qspi0_dq_3_i_ival),
    .io_pads_qspi0_dq_3_o_oval  (io_pads_qspi0_dq_3_o_oval),
    .io_pads_qspi0_dq_3_o_oe    (io_pads_qspi0_dq_3_o_oe),
    .io_pads_qspi0_cs_0_i_ival  (io_pads_qspi0_cs_0_i_ival),
    .io_pads_qspi0_cs_0_o_oval  (io_pads_qspi0_cs_0_o_oval),
    .io_pads_qspi0_cs_0_o_oe    (io_pads_qspi0_cs_0_o_oe),

    // ITCM External Interface - Always present
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

    // DTCM External Interface - Always present
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

    .sysper_icb_cmd_valid     (sysper_icb_cmd_valid),
    .sysper_icb_cmd_ready     (sysper_icb_cmd_ready),
    .sysper_icb_cmd_addr      (sysper_icb_cmd_addr ),
    .sysper_icb_cmd_read      (sysper_icb_cmd_read ),
    .sysper_icb_cmd_wdata     (sysper_icb_cmd_wdata),
    .sysper_icb_cmd_wmask     (sysper_icb_cmd_wmask),
    
    .sysper_icb_rsp_valid     (sysper_icb_rsp_valid),
    .sysper_icb_rsp_ready     (sysper_icb_rsp_ready),
    .sysper_icb_rsp_err       (sysper_icb_rsp_err  ),
    .sysper_icb_rsp_rdata     (sysper_icb_rsp_rdata),

    // Fast I/O Interface - Always present  
    .sysfio_icb_cmd_valid     (sysfio_icb_cmd_valid),
    .sysfio_icb_cmd_ready     (sysfio_icb_cmd_ready),
    .sysfio_icb_cmd_addr      (sysfio_icb_cmd_addr ),
    .sysfio_icb_cmd_read      (sysfio_icb_cmd_read ),
    .sysfio_icb_cmd_wdata     (sysfio_icb_cmd_wdata),
    .sysfio_icb_cmd_wmask     (sysfio_icb_cmd_wmask),
    
    .sysfio_icb_rsp_valid     (sysfio_icb_rsp_valid),
    .sysfio_icb_rsp_ready     (sysfio_icb_rsp_ready),
    .sysfio_icb_rsp_err       (sysfio_icb_rsp_err  ),
    .sysfio_icb_rsp_rdata     (sysfio_icb_rsp_rdata),

    // Memory Interface - Always present
    .sysmem_icb_cmd_valid  (sysmem_icb_cmd_valid),
    .sysmem_icb_cmd_ready  (sysmem_icb_cmd_ready),
    .sysmem_icb_cmd_addr   (sysmem_icb_cmd_addr ),
    .sysmem_icb_cmd_read   (sysmem_icb_cmd_read ),
    .sysmem_icb_cmd_wdata  (sysmem_icb_cmd_wdata),
    .sysmem_icb_cmd_wmask  (sysmem_icb_cmd_wmask),
    
    .sysmem_icb_rsp_valid  (sysmem_icb_rsp_valid),
    .sysmem_icb_rsp_ready  (sysmem_icb_rsp_ready),
    .sysmem_icb_rsp_err    (sysmem_icb_rsp_err  ),
    .sysmem_icb_rsp_rdata  (sysmem_icb_rsp_rdata),

    .test_mode     (test_mode), 
    .ls_clk        (lfextclk), 
    .hfclk         (hfclk   ),
    .hfclkrst      (hfclkrst),
    .corerst       (corerst),

    // JTAG
    .jtag_tck(jtag_tck),
    .jtag_tms(jtag_tms),
    .jtag_tdi(jtag_tdi),
    .jtag_tdo_i(jtag_tdo_i),
    .jtag_tdo_o(jtag_tdo_o),
    .jtag_tdo_oe(jtag_tdo_oe),

    // External Memory Interface for Boot ROM
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

    // AON
    .aon_erst_n(aon_erst_n),
    .bootrom_n(bootrom_n)
  );

  // Rest of the module remains the same...
  // (sirv_debug_module and sirv_aon_top instantiations)

endmodule