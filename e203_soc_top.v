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
                                                                         
                                                                         
                                                                         
module e203_soc_top(

    // This clock should comes from the crystal pad generated high speed clock (16MHz)
  input  wire hfextclk,
  output wire hfxoscen,// The signal to enable the crystal pad generated clock

  // This clock should comes from the crystal pad generated low speed clock (32.768KHz)
  input  wire lfextclk,
  output wire lfxoscen,// The signal to enable the crystal pad generated clock


  // The JTAG TCK is input, need to be pull-up
  input   wire io_pads_jtag_TCK_i_ival,

  // The JTAG TMS is input, need to be pull-up
  input   wire io_pads_jtag_TMS_i_ival,

  // The JTAG TDI is input, need to be pull-up
  input   wire io_pads_jtag_TDI_i_ival,

  // The JTAG TDO is output have enable
  output  wire io_pads_jtag_TDO_o_oval,
  output  wire io_pads_jtag_TDO_o_oe,

  // The GPIO are all bidir pad have enables
  input  wire [32-1:0] io_pads_gpioA_i_ival,
  output wire [32-1:0] io_pads_gpioA_o_oval,
  output wire [32-1:0] io_pads_gpioA_o_oe,

  input  wire [32-1:0] io_pads_gpioB_i_ival,
  output wire [32-1:0] io_pads_gpioB_o_oval,
  output wire [32-1:0] io_pads_gpioB_o_oe,

  //QSPI0 SCK and CS is output without enable
  output wire io_pads_qspi0_sck_o_oval,
  output wire io_pads_qspi0_cs_0_o_oval,

  //QSPI0 DQ is bidir I/O with enable, and need pull-up enable
  input   wire io_pads_qspi0_dq_0_i_ival,
  output  wire io_pads_qspi0_dq_0_o_oval,
  output  wire io_pads_qspi0_dq_0_o_oe,
  input   wire io_pads_qspi0_dq_1_i_ival,
  output  wire io_pads_qspi0_dq_1_o_oval,
  output  wire io_pads_qspi0_dq_1_o_oe,
  input   wire io_pads_qspi0_dq_2_i_ival,
  output  wire io_pads_qspi0_dq_2_o_oval,
  output  wire io_pads_qspi0_dq_2_o_oe,
  input   wire io_pads_qspi0_dq_3_i_ival,
  output  wire io_pads_qspi0_dq_3_o_oval,
  output  wire io_pads_qspi0_dq_3_o_oe,
  
  // Erst is input need to be pull-up by default
  input   wire io_pads_aon_erst_n_i_ival,

  // dbgmode are inputs need to be pull-up by default
  input  wire io_pads_dbgmode0_n_i_ival,
  input  wire io_pads_dbgmode1_n_i_ival,
  input  wire io_pads_dbgmode2_n_i_ival,

  // BootRom is input need to be pull-up by default
  input  wire io_pads_bootrom_n_i_ival,


  // dwakeup is input need to be pull-up by default
  input  wire io_pads_aon_pmu_dwakeup_n_i_ival,

      // PMU output is just output without enable
  output wire io_pads_aon_pmu_padrst_o_oval,
  output wire io_pads_aon_pmu_vddpaden_o_oval,

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
  input  wire [31:0]                  mem_icb_rsp_rdata
);


 
 wire sysper_icb_cmd_valid;
 wire sysper_icb_cmd_ready;

 wire sysfio_icb_cmd_valid;
 wire sysfio_icb_cmd_ready;

 wire sysmem_icb_cmd_valid;
 wire sysmem_icb_cmd_ready;

 e203_subsys_top u_e203_subsys_top(
    .core_mhartid      (1'b0),
  



  // External ITCM interface - always connected
    .ext2itcm_icb_cmd_valid  (1'b0),
    .ext2itcm_icb_cmd_ready  (),
    .ext2itcm_icb_cmd_addr   (16'b0),
    .ext2itcm_icb_cmd_read   (1'b0),
    .ext2itcm_icb_cmd_wdata  (32'b0),
    .ext2itcm_icb_cmd_wmask  (4'b0),
    
    .ext2itcm_icb_rsp_valid  (),
    .ext2itcm_icb_rsp_ready  (1'b0),
    .ext2itcm_icb_rsp_err    (),
    .ext2itcm_icb_rsp_rdata  (),

  // External DTCM interface - always connected
    .ext2dtcm_icb_cmd_valid  (1'b0),
    .ext2dtcm_icb_cmd_ready  (),
    .ext2dtcm_icb_cmd_addr   (16'b0),
    .ext2dtcm_icb_cmd_read   (1'b0),
    .ext2dtcm_icb_cmd_wdata  (32'b0),
    .ext2dtcm_icb_cmd_wmask  (4'b0),
    
    .ext2dtcm_icb_rsp_valid  (),
    .ext2dtcm_icb_rsp_ready  (1'b0),
    .ext2dtcm_icb_rsp_err    (),
    .ext2dtcm_icb_rsp_rdata  (),

  .sysper_icb_cmd_valid (sysper_icb_cmd_valid),
  .sysper_icb_cmd_ready (sysper_icb_cmd_ready),
  .sysper_icb_cmd_read  (), 
  .sysper_icb_cmd_addr  (), 
  .sysper_icb_cmd_wdata (), 
  .sysper_icb_cmd_wmask (), 
  
  .sysper_icb_rsp_valid (sysper_icb_cmd_valid),
  .sysper_icb_rsp_ready (sysper_icb_cmd_ready),
  .sysper_icb_rsp_err   (1'b0  ),
  .sysper_icb_rsp_rdata (32'b0),


  .sysfio_icb_cmd_valid(sysfio_icb_cmd_valid),
  .sysfio_icb_cmd_ready(sysfio_icb_cmd_ready),
  .sysfio_icb_cmd_read (), 
  .sysfio_icb_cmd_addr (), 
  .sysfio_icb_cmd_wdata(), 
  .sysfio_icb_cmd_wmask(), 
   
  .sysfio_icb_rsp_valid(sysfio_icb_cmd_valid),
  .sysfio_icb_rsp_ready(sysfio_icb_cmd_ready),
  .sysfio_icb_rsp_err  (1'b0  ),
  .sysfio_icb_rsp_rdata(32'b0),

  .sysmem_icb_cmd_valid(mem_icb_cmd_valid),
  .sysmem_icb_cmd_ready(mem_icb_cmd_ready),
  .sysmem_icb_cmd_read (mem_icb_cmd_read), 
  .sysmem_icb_cmd_addr (mem_icb_cmd_addr), 
  .sysmem_icb_cmd_wdata(mem_icb_cmd_wdata), 
  .sysmem_icb_cmd_wmask(mem_icb_cmd_wmask), 

  .sysmem_icb_rsp_valid(mem_icb_rsp_valid),
  .sysmem_icb_rsp_ready(mem_icb_rsp_ready),
  .sysmem_icb_rsp_err  (mem_icb_rsp_err  ),
  .sysmem_icb_rsp_rdata(mem_icb_rsp_rdata),

  .io_pads_jtag_TCK_i_ival    (io_pads_jtag_TCK_i_ival    ),
  .io_pads_jtag_TCK_o_oval    (),
  .io_pads_jtag_TCK_o_oe      (),
  .io_pads_jtag_TCK_o_ie      (),
  .io_pads_jtag_TCK_o_pue     (),
  .io_pads_jtag_TCK_o_ds      (),

  .io_pads_jtag_TMS_i_ival    (io_pads_jtag_TMS_i_ival    ),
  .io_pads_jtag_TMS_o_oval    (),
  .io_pads_jtag_TMS_o_oe      (),
  .io_pads_jtag_TMS_o_ie      (),
  .io_pads_jtag_TMS_o_pue     (),
  .io_pads_jtag_TMS_o_ds      (),

  .io_pads_jtag_TDI_i_ival    (io_pads_jtag_TDI_i_ival    ),
  .io_pads_jtag_TDI_o_oval    (),
  .io_pads_jtag_TDI_o_oe      (),
  .io_pads_jtag_TDI_o_ie      (),
  .io_pads_jtag_TDI_o_pue     (),
  .io_pads_jtag_TDI_o_ds      (),

  .io_pads_jtag_TDO_i_ival    (io_pads_jtag_TDO_o_oval    ),
  .io_pads_jtag_TDO_o_oval    (io_pads_jtag_TDO_o_oval    ),
  .io_pads_jtag_TDO_o_oe      (io_pads_jtag_TDO_o_oe      ),
  .io_pads_jtag_TDO_o_ie      (),
  .io_pads_jtag_TDO_o_pue     (),
  .io_pads_jtag_TDO_o_ds      (),

  .io_pads_jtag_TRST_n_i_ival (1'b1 ),
  .io_pads_jtag_TRST_n_o_oval (),
  .io_pads_jtag_TRST_n_o_oe   (),
  .io_pads_jtag_TRST_n_o_ie   (),
  .io_pads_jtag_TRST_n_o_pue  (),
  .io_pads_jtag_TRST_n_o_ds   (),

  .test_mode(1'b0),
  .test_iso_override(1'b0),

  .io_pads_gpioA_i_ival       (io_pads_gpioA_i_ival),
  .io_pads_gpioA_o_oval       (io_pads_gpioA_o_oval),
  .io_pads_gpioA_o_oe         (io_pads_gpioA_o_oe), 

  .io_pads_gpioB_i_ival       (io_pads_gpioB_i_ival),
  .io_pads_gpioB_o_oval       (io_pads_gpioB_o_oval),
  .io_pads_gpioB_o_oe         (io_pads_gpioB_o_oe), 

  .io_pads_qspi0_sck_i_ival   (1'b1),
  .io_pads_qspi0_sck_o_oval   (io_pads_qspi0_sck_o_oval),
  .io_pads_qspi0_sck_o_oe     (),
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
  .io_pads_qspi0_cs_0_i_ival  (1'b1),
  .io_pads_qspi0_cs_0_o_oval  (io_pads_qspi0_cs_0_o_oval),
  .io_pads_qspi0_cs_0_o_oe    (), 

    .hfextclk        (hfextclk),
    .hfxoscen        (hfxoscen),
    .lfextclk        (lfextclk),
    .lfxoscen        (lfxoscen),

  .io_pads_aon_erst_n_i_ival        (io_pads_aon_erst_n_i_ival       ), 
  .io_pads_aon_erst_n_o_oval        (),
  .io_pads_aon_erst_n_o_oe          (),
  .io_pads_aon_erst_n_o_ie          (),
  .io_pads_aon_erst_n_o_pue         (),
  .io_pads_aon_erst_n_o_ds          (),
  .io_pads_aon_pmu_dwakeup_n_i_ival (io_pads_aon_pmu_dwakeup_n_i_ival),
  .io_pads_aon_pmu_dwakeup_n_o_oval (),
  .io_pads_aon_pmu_dwakeup_n_o_oe   (),
  .io_pads_aon_pmu_dwakeup_n_o_ie   (),
  .io_pads_aon_pmu_dwakeup_n_o_pue  (),
  .io_pads_aon_pmu_dwakeup_n_o_ds   (),
  .io_pads_aon_pmu_vddpaden_i_ival  (1'b1 ),
  .io_pads_aon_pmu_vddpaden_o_oval  (io_pads_aon_pmu_vddpaden_o_oval ),
  .io_pads_aon_pmu_vddpaden_o_oe    (),
  .io_pads_aon_pmu_vddpaden_o_ie    (),
  .io_pads_aon_pmu_vddpaden_o_pue   (),
  .io_pads_aon_pmu_vddpaden_o_ds    (),

  
    .io_pads_aon_pmu_padrst_i_ival    (io_pads_aon_pmu_padrst_o_oval),
    .io_pads_aon_pmu_padrst_o_oval    (io_pads_aon_pmu_padrst_o_oval ),
    .io_pads_aon_pmu_padrst_o_oe      (),
    .io_pads_aon_pmu_padrst_o_ie      (),
    .io_pads_aon_pmu_padrst_o_pue     (),
    .io_pads_aon_pmu_padrst_o_ds      (),

    .io_pads_bootrom_n_i_ival       (io_pads_bootrom_n_i_ival),
    .io_pads_bootrom_n_o_oval       (),
    .io_pads_bootrom_n_o_oe         (),
    .io_pads_bootrom_n_o_ie         (),
    .io_pads_bootrom_n_o_pue        (),
    .io_pads_bootrom_n_o_ds         (),

    .io_pads_dbgmode0_n_i_ival       (io_pads_dbgmode0_n_i_ival),

    .io_pads_dbgmode1_n_i_ival       (io_pads_dbgmode1_n_i_ival),

    .io_pads_dbgmode2_n_i_ival       (io_pads_dbgmode2_n_i_ival),

  // External Memory Interface
  .mem_icb_cmd_valid(mem_icb_cmd_valid),
  .mem_icb_cmd_ready(mem_icb_cmd_ready),
  .mem_icb_cmd_addr(mem_icb_cmd_addr),
  .mem_icb_cmd_read(mem_icb_cmd_read),
  .mem_icb_cmd_wdata(mem_icb_cmd_wdata),
  .mem_icb_cmd_wmask(mem_icb_cmd_wmask),
  .mem_icb_rsp_valid(mem_icb_rsp_valid),
  .mem_icb_rsp_ready(mem_icb_rsp_ready),
  .mem_icb_rsp_err(mem_icb_rsp_err),
  .mem_icb_rsp_rdata(mem_icb_rsp_rdata)


  );


endmodule
