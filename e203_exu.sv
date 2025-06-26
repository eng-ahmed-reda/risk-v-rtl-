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
//  The main execution unit module that combines ALU and commit logic
//
// ====================================================================
`include "e203_defines.sv"

module e203_exu(
  // Core control and status
  output  excp_active,
  output  commit_mret,
  output  commit_trap,
  input   test_mode,
  output  core_wfi,
  input   tm_stop,
  input   itcm_nohold,
  input   core_cgstop,
  input   tcm_cgstop,
  output  exu_active,

  // Core configuration
  input   [32-1:0] core_mhartid,

  // Interrupt signals
  input   dbg_irq_r,
  input   [1-1:0] lcl_irq_r,
  input   ext_irq_r,
  input   sft_irq_r,
  input   tmr_irq_r,
  input   [1-1:0] evt_r,

  // Debug CSR interface
  output  [32-1:0] cmt_dpc,
  output  cmt_dpc_ena,
  output  [3-1:0] cmt_dcause,
  output  cmt_dcause_ena,
  input   wr_dcsr_ena,
  input   wr_dpc_ena,
  input   wr_dscratch_ena,
  input   [32-1:0] wr_csr_nxt,
  input   [32-1:0] dcsr_r,
  input   [32-1:0] dpc_r,
  input   [32-1:0] dscratch_r,
  input   dbg_mode,
  input   dbg_halt_r,
  input   dbg_step_r,
  input   dbg_ebreakm_r,
  input   dbg_stopcycle,

  // IFU interface
  input   i_valid,
  output  i_ready,
  input   [32-1:0] i_ir,
  input   [32-1:0] i_pc,
  input   i_pc_vld,
  input   i_misalgn,
  input   i_buserr,
  input   [5-1:0] i_rs1idx,
  input   [5-1:0] i_rs2idx,
  input   i_prdt_taken,
  input   i_muldiv_b2b,

  // WFI interface
  output  wfi_halt_ifu_req,
  input   wfi_halt_ifu_ack,

  // Pipeline flush interface
  input   pipe_flush_ack,
  output  pipe_flush_req,
  output  [32-1:0] pipe_flush_add_op1,
  output  [32-1:0] pipe_flush_add_op2,
  input   [31:0] pipe_flush_pc,

  // LSU interface
  input   lsu_o_valid,
  output  lsu_o_ready,
  input   [32-1:0] lsu_o_wbck_wdat,
  input   [2-1:0] lsu_o_wbck_itag,
  input   lsu_o_wbck_err,
  input   lsu_o_cmt_buserr,
  input   lsu_o_cmt_ld,
  input   lsu_o_cmt_st,
  input   [32-1:0] lsu_o_cmt_badaddr,

  // AGU ICB interface
  output  agu_icb_cmd_valid,
  input   agu_icb_cmd_ready,
  output  [32-1:0] agu_icb_cmd_addr,
  output  agu_icb_cmd_read,
  output  [32-1:0] agu_icb_cmd_wdata,
  output  [32/8-1:0] agu_icb_cmd_wmask,
  output  agu_icb_cmd_lock,
  output  agu_icb_cmd_excl,
  output  [1:0] agu_icb_cmd_size,
  output  agu_icb_cmd_back2agu,
  output  agu_icb_cmd_usign,
  output  [2-1:0] agu_icb_cmd_itag,
  input   agu_icb_rsp_valid,
  output  agu_icb_rsp_ready,
  input   agu_icb_rsp_err,
  input   agu_icb_rsp_excl_ok,
  input   [32-1:0] agu_icb_rsp_rdata,

  // Register file interface
  input   oitf_empty,
  output  [32-1:0] rf2ifu_x1,
  output  [32-1:0] rf2ifu_rs1,
  input   dec2ifu_rden,
  input   dec2ifu_rs1en,
  input   [5-1:0] dec2ifu_rdidx,
  input   dec2ifu_mulhsu,
  input   dec2ifu_div,
  input   dec2ifu_rem,
  input   dec2ifu_divu,
  input   dec2ifu_remu,

  // NICE interface
  `ifdef E203_HAS_NICE
  output  nice_req_valid,
  input   nice_req_ready,
  output  [32-1:0] nice_req_inst,
  output  [32-1:0] nice_req_rs1,
  output  [32-1:0] nice_req_rs2,
  input   nice_rsp_multicyc_valid,
  output  nice_rsp_multicyc_ready,
  input   [32-1:0] nice_rsp_multicyc_dat,
  input   nice_rsp_multicyc_err,
  `endif

  // NICE CSR interface
  output  nice_csr_valid,
  input   nice_csr_ready,
  output  [31:0] nice_csr_addr,
  output  nice_csr_wr,
  output  [32-1:0] nice_csr_wdata,
  input   [32-1:0] nice_csr_rdata,

  // Clock and reset
  input   clk_aon,
  input   clk,
  input   rst_n
);

  // Internal wires for ALU interface
  wire [32-1:0] i_rs1;
  wire [32-1:0] i_rs2;
  wire [32-1:0] i_imm;
  wire [32-1:0] i_info;
  wire [32-1:0] i_instr;
  wire [5-1:0] i_rdidx;
  wire i_rdwen;
  wire i_ilegl;
  wire i_misalgn_alu;
  wire i_buserr_alu;
  wire [2-1:0] i_itag;
  wire nice_xs_off;
  wire amo_wait;
  wire mdv_nob2b;

  // ALU output signals
  wire cmt_o_valid;
  wire cmt_o_ready;
  wire cmt_o_pc_vld;
  wire [32-1:0] cmt_o_pc;
  wire [32-1:0] cmt_o_instr;
  wire [32-1:0] cmt_o_imm;
  wire cmt_o_rv32;
  wire cmt_o_bjp;
  wire cmt_o_mret;
  wire cmt_o_dret;
  wire cmt_o_ecall;
  wire cmt_o_ebreak;
  wire cmt_o_fencei;
  wire cmt_o_wfi;
  wire cmt_o_ifu_misalgn;
  wire cmt_o_ifu_buserr;
  wire cmt_o_ifu_ilegl;
  wire cmt_o_bjp_prdt;
  wire cmt_o_bjp_rslv;
  wire cmt_o_misalgn;
  wire cmt_o_ld;
  wire cmt_o_stamo;
  wire cmt_o_buserr;
  wire [32-1:0] cmt_o_badaddr;

  wire wbck_o_valid;
  wire wbck_o_ready;
  wire [32-1:0] wbck_o_wdat;
  wire [5-1:0] wbck_o_rdidx;

  wire csr_ena;
  wire csr_wr_en;
  wire csr_rd_en;
  wire [12-1:0] csr_idx;
  wire nonflush_cmt_ena;
  wire csr_access_ilgl;
  wire [32-1:0] read_csr_dat;
  wire [32-1:0] wbck_csr_dat;

  // NICE interface signals
  wire nice_req_valid_alu;
  wire nice_req_ready_alu;
  wire [32-1:0] nice_req_instr_alu;
  wire [32-1:0] nice_req_rs1_alu;
  wire [32-1:0] nice_req_rs2_alu;
  wire nice_rsp_multicyc_valid_alu;
  wire nice_rsp_multicyc_ready_alu;
  wire nice_longp_wbck_valid;
  wire nice_longp_wbck_ready;
  wire [2-1:0] nice_o_itag;
  wire i_nice_cmt_off_ilgl;

  // Commit interface signals
  wire wfi_halt_exu_req;
  wire wfi_halt_exu_ack;
  wire status_mie_r;
  wire mtie_r;
  wire msie_r;
  wire meie_r;
  wire u_mode;
  wire s_mode;
  wire h_mode;
  wire m_mode;
  wire [32-1:0] csr_mtvec_r;
  wire [32-1:0] csr_epc_r;
  wire [32-1:0] csr_dpc_r;
  wire longp_excp_i_ready;
  wire longp_excp_i_valid;
  wire longp_excp_i_ld;
  wire longp_excp_i_st;
  wire longp_excp_i_buserr;
  wire longp_excp_i_badaddr;
  wire longp_excp_i_insterr;
  wire [32-1:0] longp_excp_i_pc;

  // Instantiate the ALU module
  e203_exu_alu u_e203_exu_alu(
    .i_valid(i_valid),
    .i_ready(i_ready),
    .i_longpipe(),
    .nice_xs_off(nice_xs_off),
    .amo_wait(amo_wait),
    .oitf_empty(oitf_empty),
    .i_itag(i_itag),
    .i_rs1(i_rs1),
    .i_rs2(i_rs2),
    .i_imm(i_imm),
    .i_info(i_info),
    .i_pc(i_pc),
    .i_instr(i_instr),
    .i_pc_vld(i_pc_vld),
    .i_rdidx(i_rdidx),
    .i_rdwen(i_rdwen),
    .i_ilegl(i_ilegl),
    .i_buserr(i_buserr_alu),
    .i_misalgn(i_misalgn_alu),
    .flush_req(),
    .flush_pulse(),
    .cmt_o_valid(cmt_o_valid),
    .cmt_o_ready(cmt_o_ready),
    .cmt_o_pc_vld(cmt_o_pc_vld),
    .cmt_o_pc(cmt_o_pc),
    .cmt_o_instr(cmt_o_instr),
    .cmt_o_imm(cmt_o_imm),
    .cmt_o_rv32(cmt_o_rv32),
    .cmt_o_bjp(cmt_o_bjp),
    .cmt_o_mret(cmt_o_mret),
    .cmt_o_dret(cmt_o_dret),
    .cmt_o_ecall(cmt_o_ecall),
    .cmt_o_ebreak(cmt_o_ebreak),
    .cmt_o_fencei(cmt_o_fencei),
    .cmt_o_wfi(cmt_o_wfi),
    .cmt_o_ifu_misalgn(cmt_o_ifu_misalgn),
    .cmt_o_ifu_buserr(cmt_o_ifu_buserr),
    .cmt_o_ifu_ilegl(cmt_o_ifu_ilegl),
    .cmt_o_bjp_prdt(cmt_o_bjp_prdt),
    .cmt_o_bjp_rslv(cmt_o_bjp_rslv),
    .cmt_o_misalgn(cmt_o_misalgn),
    .cmt_o_ld(cmt_o_ld),
    .cmt_o_stamo(cmt_o_stamo),
    .cmt_o_buserr(cmt_o_buserr),
    .cmt_o_badaddr(cmt_o_badaddr),
    .wbck_o_valid(wbck_o_valid),
    .wbck_o_ready(wbck_o_ready),
    .wbck_o_wdat(wbck_o_wdat),
    .wbck_o_rdidx(wbck_o_rdidx),
    .mdv_nob2b(mdv_nob2b),
    .csr_ena(csr_ena),
    .csr_wr_en(csr_wr_en),
    .csr_rd_en(csr_rd_en),
    .csr_idx(csr_idx),
    .nonflush_cmt_ena(nonflush_cmt_ena),
    .csr_access_ilgl(csr_access_ilgl),
    .read_csr_dat(read_csr_dat),
    .wbck_csr_dat(wbck_csr_dat),
    .nice_csr_valid(nice_csr_valid),
    .nice_csr_ready(nice_csr_ready),
    .nice_csr_addr(nice_csr_addr),
    .nice_csr_wr(nice_csr_wr),
    .nice_csr_wdata(nice_csr_wdata),
    .nice_csr_rdata(nice_csr_rdata),
    .agu_icb_cmd_valid(agu_icb_cmd_valid),
    .agu_icb_cmd_ready(agu_icb_cmd_ready),
    .agu_icb_cmd_addr(agu_icb_cmd_addr),
    .agu_icb_cmd_read(agu_icb_cmd_read),
    .agu_icb_cmd_wdata(agu_icb_cmd_wdata),
    .agu_icb_cmd_wmask(agu_icb_cmd_wmask),
    .agu_icb_cmd_lock(agu_icb_cmd_lock),
    .agu_icb_cmd_excl(agu_icb_cmd_excl),
    .agu_icb_cmd_size(agu_icb_cmd_size),
    .agu_icb_cmd_back2agu(agu_icb_cmd_back2agu),
    .agu_icb_cmd_usign(agu_icb_cmd_usign),
    .agu_icb_cmd_itag(agu_icb_cmd_itag),
    .agu_icb_rsp_valid(agu_icb_rsp_valid),
    .agu_icb_rsp_ready(agu_icb_rsp_ready),
    .agu_icb_rsp_err(agu_icb_rsp_err),
    .agu_icb_rsp_excl_ok(agu_icb_rsp_excl_ok),
    .agu_icb_rsp_rdata(agu_icb_rsp_rdata),
    .nice_req_valid(nice_req_valid_alu),
    .nice_req_ready(nice_req_ready_alu),
    .nice_req_instr(nice_req_instr_alu),
    .nice_req_rs1(nice_req_rs1_alu),
    .nice_req_rs2(nice_req_rs2_alu),
    .nice_rsp_multicyc_valid(nice_rsp_multicyc_valid_alu),
    .nice_rsp_multicyc_ready(nice_rsp_multicyc_ready_alu),
    .nice_longp_wbck_valid(nice_longp_wbck_valid),
    .nice_longp_wbck_ready(nice_longp_wbck_ready),
    .nice_o_itag(nice_o_itag),
    .i_nice_cmt_off_ilgl(i_nice_cmt_off_ilgl),
    .clk(clk),
    .rst_n(rst_n)
  );

  // Instantiate the commit module
  e203_exu_commit u_e203_exu_commit(
    .commit_mret(commit_mret),
    .commit_trap(commit_trap),
    .core_wfi(core_wfi),
    .nonflush_cmt_ena(nonflush_cmt_ena),
    .excp_active(excp_active),
    .amo_wait(amo_wait),
    .wfi_halt_ifu_req(wfi_halt_ifu_req),
    .wfi_halt_exu_req(wfi_halt_exu_req),
    .wfi_halt_ifu_ack(wfi_halt_ifu_ack),
    .wfi_halt_exu_ack(wfi_halt_exu_ack),
    .dbg_irq_r(dbg_irq_r),
    .lcl_irq_r(lcl_irq_r),
    .ext_irq_r(ext_irq_r),
    .sft_irq_r(sft_irq_r),
    .tmr_irq_r(tmr_irq_r),
    .evt_r(evt_r),
    .status_mie_r(status_mie_r),
    .mtie_r(mtie_r),
    .msie_r(msie_r),
    .meie_r(meie_r),
    .alu_cmt_i_valid(cmt_o_valid),
    .alu_cmt_i_ready(cmt_o_ready),
    .alu_cmt_i_pc(cmt_o_pc),
    .alu_cmt_i_instr(cmt_o_instr),
    .alu_cmt_i_pc_vld(cmt_o_pc_vld),
    .alu_cmt_i_imm(cmt_o_imm),
    .alu_cmt_i_rv32(cmt_o_rv32),
    .alu_cmt_i_bjp(cmt_o_bjp),
    .alu_cmt_i_wfi(cmt_o_wfi),
    .alu_cmt_i_fencei(cmt_o_fencei),
    .alu_cmt_i_mret(cmt_o_mret),
    .alu_cmt_i_dret(cmt_o_dret),
    .alu_cmt_i_ecall(cmt_o_ecall),
    .alu_cmt_i_ebreak(cmt_o_ebreak),
    .alu_cmt_i_ifu_misalgn(cmt_o_ifu_misalgn),
    .alu_cmt_i_ifu_buserr(cmt_o_ifu_buserr),
    .alu_cmt_i_ifu_ilegl(cmt_o_ifu_ilegl),
    .alu_cmt_i_bjp_prdt(cmt_o_bjp_prdt),
    .alu_cmt_i_bjp_rslv(cmt_o_bjp_rslv),
    .alu_cmt_i_misalgn(cmt_o_misalgn),
    .alu_cmt_i_ld(cmt_o_ld),
    .alu_cmt_i_stamo(cmt_o_stamo),
    .alu_cmt_i_buserr(cmt_o_buserr),
    .alu_cmt_i_badaddr(cmt_o_badaddr),
    .cmt_badaddr(),
    .cmt_badaddr_ena(),
    .cmt_epc(),
    .cmt_epc_ena(),
    .cmt_cause(),
    .cmt_cause_ena(),
    .cmt_instret_ena(),
    .cmt_status_ena(),
    .cmt_dpc(cmt_dpc),
    .cmt_dpc_ena(cmt_dpc_ena),
    .cmt_dcause(cmt_dcause),
    .cmt_dcause_ena(cmt_dcause_ena),
    .cmt_mret_ena(),
    .csr_epc_r(csr_epc_r),
    .csr_dpc_r(csr_dpc_r),
    .csr_mtvec_r(csr_mtvec_r),
    .dbg_mode(dbg_mode),
    .dbg_halt_r(dbg_halt_r),
    .dbg_step_r(dbg_step_r),
    .dbg_ebreakm_r(dbg_ebreakm_r),
    .oitf_empty(oitf_empty),
    .u_mode(u_mode),
    .s_mode(s_mode),
    .h_mode(h_mode),
    .m_mode(m_mode),
    .longp_excp_i_ready(longp_excp_i_ready),
    .longp_excp_i_valid(longp_excp_i_valid),
    .longp_excp_i_ld(longp_excp_i_ld),
    .longp_excp_i_st(longp_excp_i_st),
    .longp_excp_i_buserr(longp_excp_i_buserr),
    .longp_excp_i_badaddr(longp_excp_i_badaddr),
    .longp_excp_i_insterr(longp_excp_i_insterr),
    .longp_excp_i_pc(longp_excp_i_pc),
    .flush_pulse(),
    .flush_req(),
    .pipe_flush_ack(pipe_flush_ack),
    .pipe_flush_req(pipe_flush_req),
    .pipe_flush_add_op1(pipe_flush_add_op1),
    .pipe_flush_add_op2(pipe_flush_add_op2),
    .clk(clk),
    .rst_n(rst_n)
  );

  // Connect NICE interface
  `ifdef E203_HAS_NICE
  assign nice_req_valid = nice_req_valid_alu;
  assign nice_req_ready_alu = nice_req_ready;
  assign nice_req_inst = nice_req_instr_alu;
  assign nice_req_rs1 = nice_req_rs1_alu;
  assign nice_req_rs2 = nice_req_rs2_alu;
  assign nice_rsp_multicyc_valid_alu = nice_rsp_multicyc_valid;
  assign nice_rsp_multicyc_ready = nice_rsp_multicyc_ready_alu;
  `endif

  // Connect LSU interface
  assign lsu_o_ready = 1'b1; // Always ready for now

  // Connect register file interface (simplified)
  assign rf2ifu_x1 = 32'h0;
  assign rf2ifu_rs1 = 32'h0;

  // Set exu_active
  assign exu_active = 1'b1;

  // Default values for unused signals
  assign i_rs1 = 32'h0;
  assign i_rs2 = 32'h0;
  assign i_imm = 32'h0;
  assign i_info = 32'h0;
  assign i_instr = i_ir;
  assign i_rdidx = 5'h0;
  assign i_rdwen = 1'b0;
  assign i_ilegl = 1'b0;
  assign i_buserr_alu = i_buserr;
  assign i_misalgn_alu = i_misalgn;
  assign i_itag = 2'h0;
  assign nice_xs_off = 1'b0;
  assign mdv_nob2b = 1'b0;
  assign i_nice_cmt_off_ilgl = 1'b0;

  // Default values for CSR interface
  assign status_mie_r = 1'b0;
  assign mtie_r = 1'b0;
  assign msie_r = 1'b0;
  assign meie_r = 1'b0;
  assign u_mode = 1'b0;
  assign s_mode = 1'b0;
  assign h_mode = 1'b0;
  assign m_mode = 1'b1;
  assign csr_mtvec_r = 32'h0;
  assign csr_epc_r = 32'h0;
  assign csr_dpc_r = 32'h0;
  assign longp_excp_i_ready = 1'b1;
  assign longp_excp_i_valid = 1'b0;
  assign longp_excp_i_ld = 1'b0;
  assign longp_excp_i_st = 1'b0;
  assign longp_excp_i_buserr = 1'b0;
  assign longp_excp_i_badaddr = 32'h0;
  assign longp_excp_i_insterr = 1'b0;
  assign longp_excp_i_pc = 32'h0;

endmodule