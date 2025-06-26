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
//  The Write-Back module to arbitrate the write-back request to regfile
//
// ====================================================================

module e203_exu_wbck(

  //////////////////////////////////////////////////////////////
  // The ALU Write-Back Interface
  input  alu_wbck_i_valid, // Handshake valid
  output alu_wbck_i_ready, // Handshake ready
  input  [32-1:0] alu_wbck_i_wdat,
  input  [5-1:0] alu_wbck_i_rdidx,
  input  alu_wbck_i_rdwen,
  input  alu_wbck_i_rdfpu,
  input  alu_wbck_i_pc,
  input  alu_wbck_i_irq,
  input  alu_wbck_i_bjp,
  input  alu_wbck_i_misalgn,
  input  alu_wbck_i_buserr,
  input  alu_wbck_i_ecall,
  input  alu_wbck_i_ebreak,
  input  alu_wbck_i_fencei,
  input  alu_wbck_i_ecallmret,
  input  alu_wbck_i_ecallsret,
  input  alu_wbck_i_ecalluret,
  input  alu_wbck_i_wfi,
  input  alu_wbck_i_ifu_muldiv_b2b,
  input  alu_wbck_i_ifu_busy,
  input  alu_wbck_i_ifu_holdup,
  input  alu_wbck_i_oitf_empty,
  input  alu_wbck_i_oitf_ret_ena,
  input  alu_wbck_i_oitf_ret_ptr,
  input  alu_wbck_i_oitf_ret_rdidx,
  input  alu_wbck_i_oitf_ret_rdwen,
  input  alu_wbck_i_oitf_ret_rdfpu,
  input  alu_wbck_i_oitf_ret_pc,
  input  alu_wbck_i_oitf_ret_irq,
  input  alu_wbck_i_oitf_ret_bjp,
  input  alu_wbck_i_oitf_ret_misalgn,
  input  alu_wbck_i_oitf_ret_buserr,
  input  alu_wbck_i_oitf_ret_ecall,
  input  alu_wbck_i_oitf_ret_ebreak,
  input  alu_wbck_i_oitf_ret_fencei,
  input  alu_wbck_i_oitf_ret_ecallmret,
  input  alu_wbck_i_oitf_ret_ecallsret,
  input  alu_wbck_i_oitf_ret_ecalluret,
  input  alu_wbck_i_oitf_ret_wfi,
  input  alu_wbck_i_oitf_ret_ifu_muldiv_b2b,
  input  alu_wbck_i_oitf_ret_ifu_busy,
  input  alu_wbck_i_oitf_ret_ifu_holdup,

  //////////////////////////////////////////////////////////////
  // The Longp Write-Back Interface
  input  longp_wbck_i_valid, // Handshake valid
  output longp_wbck_i_ready, // Handshake ready
  input  [32-1:0] longp_wbck_i_wdat,
  input  [5-1:0] longp_wbck_i_flags,
  input  [5-1:0] longp_wbck_i_rdidx,
  input  longp_wbck_i_rdwen,
  input  longp_wbck_i_rdfpu,
  input  longp_wbck_i_pc,
  input  longp_wbck_i_irq,
  input  longp_wbck_i_bjp,
  input  longp_wbck_i_misalgn,
  input  longp_wbck_i_buserr,
  input  longp_wbck_i_ecall,
  input  longp_wbck_i_ebreak,
  input  longp_wbck_i_fencei,
  input  longp_wbck_i_ecallmret,
  input  longp_wbck_i_ecallsret,
  input  longp_wbck_i_ecalluret,
  input  longp_wbck_i_wfi,
  input  longp_wbck_i_ifu_muldiv_b2b,
  input  longp_wbck_i_ifu_busy,
  input  longp_wbck_i_ifu_holdup,
  input  longp_wbck_i_oitf_empty,
  input  longp_wbck_i_oitf_ret_ena,
  input  longp_wbck_i_oitf_ret_ptr,
  input  longp_wbck_i_oitf_ret_rdidx,
  input  longp_wbck_i_oitf_ret_rdwen,
  input  longp_wbck_i_oitf_ret_rdfpu,
  input  longp_wbck_i_oitf_ret_pc,
  input  longp_wbck_i_oitf_ret_irq,
  input  longp_wbck_i_oitf_ret_bjp,
  input  longp_wbck_i_oitf_ret_misalgn,
  input  longp_wbck_i_oitf_ret_buserr,
  input  longp_wbck_i_oitf_ret_ecall,
  input  longp_wbck_i_oitf_ret_ebreak,
  input  longp_wbck_i_oitf_ret_fencei,
  input  longp_wbck_i_oitf_ret_ecallmret,
  input  longp_wbck_i_oitf_ret_ecallsret,
  input  longp_wbck_i_oitf_ret_ecalluret,
  input  longp_wbck_i_oitf_ret_wfi,
  input  longp_wbck_i_oitf_ret_ifu_muldiv_b2b,
  input  longp_wbck_i_oitf_ret_ifu_busy,
  input  longp_wbck_i_oitf_ret_ifu_holdup,

  //////////////////////////////////////////////////////////////
  // The Final arbitrated Write-Back Interface to Regfile
  output  rf_wbck_o_ena,
  output  [32-1:0] rf_wbck_o_wdat,
  output  [5-1:0] rf_wbck_o_rdidx,
  output  rf_wbck_o_rdwen,
  output  rf_wbck_o_rdfpu,
  output  rf_wbck_o_pc,
  output  rf_wbck_o_irq,
  output  rf_wbck_o_bjp,
  output  rf_wbck_o_misalgn,
  output  rf_wbck_o_buserr,
  output  rf_wbck_o_ecall,
  output  rf_wbck_o_ebreak,
  output  rf_wbck_o_fencei,
  output  rf_wbck_o_ecallmret,
  output  rf_wbck_o_ecallsret,
  output  rf_wbck_o_ecalluret,
  output  rf_wbck_o_wfi,
  output  rf_wbck_o_ifu_muldiv_b2b,
  output  rf_wbck_o_ifu_busy,
  output  rf_wbck_o_ifu_holdup,
  output  rf_wbck_o_oitf_empty,
  output  rf_wbck_o_oitf_ret_ena,
  output  rf_wbck_o_oitf_ret_ptr,
  output  rf_wbck_o_oitf_ret_rdidx,
  output  rf_wbck_o_oitf_ret_rdwen,
  output  rf_wbck_o_oitf_ret_rdfpu,
  output  rf_wbck_o_oitf_ret_pc,
  output  rf_wbck_o_oitf_ret_irq,
  output  rf_wbck_o_oitf_ret_bjp,
  output  rf_wbck_o_oitf_ret_misalgn,
  output  rf_wbck_o_oitf_ret_buserr,
  output  rf_wbck_o_oitf_ret_ecall,
  output  rf_wbck_o_oitf_ret_ebreak,
  output  rf_wbck_o_oitf_ret_fencei,
  output  rf_wbck_o_oitf_ret_ecallmret,
  output  rf_wbck_o_oitf_ret_ecallsret,
  output  rf_wbck_o_oitf_ret_ecalluret,
  output  rf_wbck_o_oitf_ret_wfi,
  output  rf_wbck_o_oitf_ret_ifu_muldiv_b2b,
  output  rf_wbck_o_oitf_ret_ifu_busy,
  output  rf_wbck_o_oitf_ret_ifu_holdup,

  input  clk,
  input  rst_n
  );


  // The ALU instruction can write-back only when there is no any 
  //  long pipeline instruction writing-back
  //    * Since ALU is the 1 cycle instructions, it have lowest 
  //      priority in arbitration
  wire wbck_ready4alu = (~longp_wbck_i_valid);
  wire wbck_sel_alu = alu_wbck_i_valid & wbck_ready4alu;
  // The Long-pipe instruction can always write-back since it have high priority 
  wire wbck_ready4longp = 1'b1;
  wire wbck_sel_longp = longp_wbck_i_valid & wbck_ready4longp;



  //////////////////////////////////////////////////////////////
  // The Final arbitrated Write-Back Interface
  wire rf_wbck_o_ready = 1'b1; // Regfile is always ready to be write because it just has 1 w-port

  wire wbck_i_ready;
  wire wbck_i_valid;
  wire [32-1:0] wbck_i_wdat;
  wire [5-1:0] wbck_i_flags;
  wire [5-1:0] wbck_i_rdidx;
  wire wbck_i_rdwen;
  wire wbck_i_rdfpu;
  wire wbck_i_pc;
  wire wbck_i_irq;
  wire wbck_i_bjp;
  wire wbck_i_misalgn;
  wire wbck_i_buserr;
  wire wbck_i_ecall;
  wire wbck_i_ebreak;
  wire wbck_i_fencei;
  wire wbck_i_ecallmret;
  wire wbck_i_ecallsret;
  wire wbck_i_ecalluret;
  wire wbck_i_wfi;
  wire wbck_i_ifu_muldiv_b2b;
  wire wbck_i_ifu_busy;
  wire wbck_i_ifu_holdup;
  wire wbck_i_oitf_empty;
  wire wbck_i_oitf_ret_ena;
  wire wbck_i_oitf_ret_ptr;
  wire wbck_i_oitf_ret_rdidx;
  wire wbck_i_oitf_ret_rdwen;
  wire wbck_i_oitf_ret_rdfpu;
  wire wbck_i_oitf_ret_pc;
  wire wbck_i_oitf_ret_irq;
  wire wbck_i_oitf_ret_bjp;
  wire wbck_i_oitf_ret_misalgn;
  wire wbck_i_oitf_ret_buserr;
  wire wbck_i_oitf_ret_ecall;
  wire wbck_i_oitf_ret_ebreak;
  wire wbck_i_oitf_ret_fencei;
  wire wbck_i_oitf_ret_ecallmret;
  wire wbck_i_oitf_ret_ecallsret;
  wire wbck_i_oitf_ret_ecalluret;
  wire wbck_i_oitf_ret_wfi;
  wire wbck_i_oitf_ret_ifu_muldiv_b2b;
  wire wbck_i_oitf_ret_ifu_busy;
  wire wbck_i_oitf_ret_ifu_holdup;

  assign alu_wbck_i_ready   = wbck_ready4alu   & wbck_i_ready;
  assign longp_wbck_i_ready = wbck_ready4longp & wbck_i_ready;

  assign wbck_i_valid = wbck_sel_alu ? alu_wbck_i_valid : longp_wbck_i_valid;
  assign wbck_i_wdat  = wbck_sel_alu ? alu_wbck_i_wdat  : longp_wbck_i_wdat;
  assign wbck_i_flags = wbck_sel_alu ? 5'b0  : longp_wbck_i_flags;
  assign wbck_i_rdidx = wbck_sel_alu ? alu_wbck_i_rdidx : longp_wbck_i_rdidx;
  assign wbck_i_rdwen = wbck_sel_alu ? alu_wbck_i_rdwen : longp_wbck_i_rdwen;
  assign wbck_i_rdfpu = wbck_sel_alu ? alu_wbck_i_rdfpu : longp_wbck_i_rdfpu;
  assign wbck_i_pc    = wbck_sel_alu ? alu_wbck_i_pc    : longp_wbck_i_pc   ;
  assign wbck_i_irq   = wbck_sel_alu ? alu_wbck_i_irq   : longp_wbck_i_irq  ;
  assign wbck_i_bjp   = wbck_sel_alu ? alu_wbck_i_bjp   : longp_wbck_i_bjp  ;
  assign wbck_i_misalgn = wbck_sel_alu ? alu_wbck_i_misalgn : longp_wbck_i_misalgn;
  assign wbck_i_buserr = wbck_sel_alu ? alu_wbck_i_buserr : longp_wbck_i_buserr;
  assign wbck_i_ecall = wbck_sel_alu ? alu_wbck_i_ecall : longp_wbck_i_ecall;
  assign wbck_i_ebreak = wbck_sel_alu ? alu_wbck_i_ebreak : longp_wbck_i_ebreak;
  assign wbck_i_fencei = wbck_sel_alu ? alu_wbck_i_fencei : longp_wbck_i_fencei;
  assign wbck_i_ecallmret = wbck_sel_alu ? alu_wbck_i_ecallmret : longp_wbck_i_ecallmret;
  assign wbck_i_ecallsret = wbck_sel_alu ? alu_wbck_i_ecallsret : longp_wbck_i_ecallsret;
  assign wbck_i_ecalluret = wbck_sel_alu ? alu_wbck_i_ecalluret : longp_wbck_i_ecalluret;
  assign wbck_i_wfi = wbck_sel_alu ? alu_wbck_i_wfi : longp_wbck_i_wfi;
  assign wbck_i_ifu_muldiv_b2b = wbck_sel_alu ? alu_wbck_i_ifu_muldiv_b2b : longp_wbck_i_ifu_muldiv_b2b;
  assign wbck_i_ifu_busy = wbck_sel_alu ? alu_wbck_i_ifu_busy : longp_wbck_i_ifu_busy;
  assign wbck_i_ifu_holdup = wbck_sel_alu ? alu_wbck_i_ifu_holdup : longp_wbck_i_ifu_holdup;
  assign wbck_i_oitf_empty = wbck_sel_alu ? alu_wbck_i_oitf_empty : longp_wbck_i_oitf_empty;
  assign wbck_i_oitf_ret_ena = wbck_sel_alu ? alu_wbck_i_oitf_ret_ena : longp_wbck_i_oitf_ret_ena;
  assign wbck_i_oitf_ret_ptr = wbck_sel_alu ? alu_wbck_i_oitf_ret_ptr : longp_wbck_i_oitf_ret_ptr;
  assign wbck_i_oitf_ret_rdidx = wbck_sel_alu ? alu_wbck_i_oitf_ret_rdidx : longp_wbck_i_oitf_ret_rdidx;
  assign wbck_i_oitf_ret_rdwen = wbck_sel_alu ? alu_wbck_i_oitf_ret_rdwen : longp_wbck_i_oitf_ret_rdwen;
  assign wbck_i_oitf_ret_rdfpu = wbck_sel_alu ? alu_wbck_i_oitf_ret_rdfpu : longp_wbck_i_oitf_ret_rdfpu;
  assign wbck_i_oitf_ret_pc = wbck_sel_alu ? alu_wbck_i_oitf_ret_pc : longp_wbck_i_oitf_ret_pc;
  assign wbck_i_oitf_ret_irq = wbck_sel_alu ? alu_wbck_i_oitf_ret_irq : longp_wbck_i_oitf_ret_irq;
  assign wbck_i_oitf_ret_bjp = wbck_sel_alu ? alu_wbck_i_oitf_ret_bjp : longp_wbck_i_oitf_ret_bjp;
  assign wbck_i_oitf_ret_misalgn = wbck_sel_alu ? alu_wbck_i_oitf_ret_misalgn : longp_wbck_i_oitf_ret_misalgn;
  assign wbck_i_oitf_ret_buserr = wbck_sel_alu ? alu_wbck_i_oitf_ret_buserr : longp_wbck_i_oitf_ret_buserr;
  assign wbck_i_oitf_ret_ecall = wbck_sel_alu ? alu_wbck_i_oitf_ret_ecall : longp_wbck_i_oitf_ret_ecall;
  assign wbck_i_oitf_ret_ebreak = wbck_sel_alu ? alu_wbck_i_oitf_ret_ebreak : longp_wbck_i_oitf_ret_ebreak;
  assign wbck_i_oitf_ret_fencei = wbck_sel_alu ? alu_wbck_i_oitf_ret_fencei : longp_wbck_i_oitf_ret_fencei;
  assign wbck_i_oitf_ret_ecallmret = wbck_sel_alu ? alu_wbck_i_oitf_ret_ecallmret : longp_wbck_i_oitf_ret_ecallmret;
  assign wbck_i_oitf_ret_ecallsret = wbck_sel_alu ? alu_wbck_i_oitf_ret_ecallsret : longp_wbck_i_oitf_ret_ecallsret;
  assign wbck_i_oitf_ret_ecalluret = wbck_sel_alu ? alu_wbck_i_oitf_ret_ecalluret : longp_wbck_i_oitf_ret_ecalluret;
  assign wbck_i_oitf_ret_wfi = wbck_sel_alu ? alu_wbck_i_oitf_ret_wfi : longp_wbck_i_oitf_ret_wfi;
  assign wbck_i_oitf_ret_ifu_muldiv_b2b = wbck_sel_alu ? alu_wbck_i_oitf_ret_ifu_muldiv_b2b : longp_wbck_i_oitf_ret_ifu_muldiv_b2b;
  assign wbck_i_oitf_ret_ifu_busy = wbck_sel_alu ? alu_wbck_i_oitf_ret_ifu_busy : longp_wbck_i_oitf_ret_ifu_busy;
  assign wbck_i_oitf_ret_ifu_holdup = wbck_sel_alu ? alu_wbck_i_oitf_ret_ifu_holdup : longp_wbck_i_oitf_ret_ifu_holdup;

  // If it have error or non-rdwen it will not be send to this module
  //   instead have been killed at EU level, so it is always need to 
  //   write back into regfile at here
  assign wbck_i_ready  = rf_wbck_o_ready;
  wire rf_wbck_o_valid = wbck_i_valid;

  wire wbck_o_ena   = rf_wbck_o_valid & rf_wbck_o_ready;

  assign rf_wbck_o_ena   = wbck_o_ena & (~wbck_i_rdfpu);
  assign rf_wbck_o_wdat  = wbck_i_wdat[32-1:0];
  assign rf_wbck_o_rdidx = wbck_i_rdidx;
  assign rf_wbck_o_rdwen = wbck_i_rdwen;
  assign rf_wbck_o_rdfpu = wbck_i_rdfpu;
  assign rf_wbck_o_pc    = wbck_i_pc;
  assign rf_wbck_o_irq   = wbck_i_irq;
  assign rf_wbck_o_bjp   = wbck_i_bjp;
  assign rf_wbck_o_misalgn = wbck_i_misalgn;
  assign rf_wbck_o_buserr = wbck_i_buserr;
  assign rf_wbck_o_ecall = wbck_i_ecall;
  assign rf_wbck_o_ebreak = wbck_i_ebreak;
  assign rf_wbck_o_fencei = wbck_i_fencei;
  assign rf_wbck_o_ecallmret = wbck_i_ecallmret;
  assign rf_wbck_o_ecallsret = wbck_i_ecallsret;
  assign rf_wbck_o_ecalluret = wbck_i_ecalluret;
  assign rf_wbck_o_wfi = wbck_i_wfi;
  assign rf_wbck_o_ifu_muldiv_b2b = wbck_i_ifu_muldiv_b2b;
  assign rf_wbck_o_ifu_busy = wbck_i_ifu_busy;
  assign rf_wbck_o_ifu_holdup = wbck_i_ifu_holdup;
  assign rf_wbck_o_oitf_empty = wbck_i_oitf_empty;
  assign rf_wbck_o_oitf_ret_ena = wbck_i_oitf_ret_ena;
  assign rf_wbck_o_oitf_ret_ptr = wbck_i_oitf_ret_ptr;
  assign rf_wbck_o_oitf_ret_rdidx = wbck_i_oitf_ret_rdidx;
  assign rf_wbck_o_oitf_ret_rdwen = wbck_i_oitf_ret_rdwen;
  assign rf_wbck_o_oitf_ret_rdfpu = wbck_i_oitf_ret_rdfpu;
  assign rf_wbck_o_oitf_ret_pc = wbck_i_oitf_ret_pc;
  assign rf_wbck_o_oitf_ret_irq = wbck_i_oitf_ret_irq;
  assign rf_wbck_o_oitf_ret_bjp = wbck_i_oitf_ret_bjp;
  assign rf_wbck_o_oitf_ret_misalgn = wbck_i_oitf_ret_misalgn;
  assign rf_wbck_o_oitf_ret_buserr = wbck_i_oitf_ret_buserr;
  assign rf_wbck_o_oitf_ret_ecall = wbck_i_oitf_ret_ecall;
  assign rf_wbck_o_oitf_ret_ebreak = wbck_i_oitf_ret_ebreak;
  assign rf_wbck_o_oitf_ret_fencei = wbck_i_oitf_ret_fencei;
  assign rf_wbck_o_oitf_ret_ecallmret = wbck_i_oitf_ret_ecallmret;
  assign rf_wbck_o_oitf_ret_ecallsret = wbck_i_oitf_ret_ecallsret;
  assign rf_wbck_o_oitf_ret_ecalluret = wbck_i_oitf_ret_ecalluret;
  assign rf_wbck_o_oitf_ret_wfi = wbck_i_oitf_ret_wfi;
  assign rf_wbck_o_oitf_ret_ifu_muldiv_b2b = wbck_i_oitf_ret_ifu_muldiv_b2b;
  assign rf_wbck_o_oitf_ret_ifu_busy = wbck_i_oitf_ret_ifu_busy;
  assign rf_wbck_o_oitf_ret_ifu_holdup = wbck_i_oitf_ret_ifu_holdup;
  assign rf_wbck_o_oitf_ret_oitf_empty = wbck_i_oitf_empty;

endmodule                                      
                                               
                                               
                                               
