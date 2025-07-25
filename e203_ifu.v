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
//  The IFU to implement entire instruction fetch unit.
//
// ====================================================================

module e203_ifu(
  output[32-1:0] inspect_pc,
  output ifu_active,
  input  itcm_nohold,

  input  [32-1:0] pc_rtvec,  
  input  ifu2itcm_holdup,

  // The ITCM address region indication signal
  input [32-1:0] itcm_region_indic,

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Bus Interface to ITCM, internal protocol called ICB (Internal Chip Bus)
  //    * Bus cmd channel
  output ifu2itcm_icb_cmd_valid, // Handshake valid
  input  ifu2itcm_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  output [16-1:0]   ifu2itcm_icb_cmd_addr, // Bus transaction start addr 

  //    * Bus RSP channel
  input  ifu2itcm_icb_rsp_valid, // Response valid 
  output ifu2itcm_icb_rsp_ready, // Response ready
  input  ifu2itcm_icb_rsp_err,   // Response error
            // Note: the RSP rdata is inline with AXI definition
  input  [63:0] ifu2itcm_icb_rsp_rdata, 

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Bus Interface to System Memory, internal protocol called ICB (Internal Chip Bus)
  //    * Bus cmd channel
  output ifu2biu_icb_cmd_valid, // Handshake valid
  input  ifu2biu_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  output [32-1:0]   ifu2biu_icb_cmd_addr, // Bus transaction start addr 

  //    * Bus RSP channel
  input  ifu2biu_icb_rsp_valid, // Response valid 
  output ifu2biu_icb_rsp_ready, // Response ready
  input  ifu2biu_icb_rsp_err,   // Response error
            // Note: the RSP rdata is inline with AXI definition
  input  [32-1:0] ifu2biu_icb_rsp_rdata, 

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The IR stage to EXU interface
  output [32-1:0] ifu_o_ir,// The instruction register
  output [32-1:0] ifu_o_pc,   // The PC register along with
  output ifu_o_pc_vld,
  output ifu_o_misalgn,                  // The fetch misalign 
  output ifu_o_buserr,                   // The fetch bus error
  output [5-1:0] ifu_o_rs1idx,
  output [5-1:0] ifu_o_rs2idx,
  output ifu_o_prdt_taken,               // The Bxx is predicted as taken
  output ifu_o_muldiv_b2b,               
  output ifu_o_valid, // Handshake signals with EXU stage
  input  ifu_o_ready,

  output  pipe_flush_ack,
  input   pipe_flush_req,
  input   [32-1:0] pipe_flush_add_op1,  
  input   [32-1:0] pipe_flush_add_op2,
  input   [32-1:0] pipe_flush_pc,  

      
  // The halt request come from other commit stage
  //   If the ifu_halt_req is asserting, then IFU will stop fetching new 
  //     instructions and after the oustanding transactions are completed,
  //     asserting the ifu_halt_ack as the response.
  //   The IFU will resume fetching only after the ifu_halt_req is deasserted
  input  ifu_halt_req,
  output ifu_halt_ack,

  input  oitf_empty,
  input  [32-1:0] rf2ifu_x1,
  input  [32-1:0] rf2ifu_rs1,
  input  dec2ifu_rden,
  input  dec2ifu_rs1en,
  input  [5-1:0] dec2ifu_rdidx,
  input  dec2ifu_mulhsu,
  input  dec2ifu_div   ,
  input  dec2ifu_rem   ,
  input  dec2ifu_divu  ,
  input  dec2ifu_remu  ,

  input  clk,
  input  rst_n
  );

  
  wire ifu_req_valid; 
  wire ifu_req_ready; 
  wire [32-1:0]   ifu_req_pc; 
  wire ifu_req_seq;
  wire ifu_req_seq_rv32;
  wire [31:0] ifu_req_last_pc;
  wire ifu_rsp_valid; 
  wire ifu_rsp_ready; 
  wire ifu_rsp_err;   
  wire [63:0] ifu_rsp_instr; 

  e203_ifu_ifetch u_e203_ifu_ifetch(
    .inspect_pc   (inspect_pc),
    .pc_rtvec      (pc_rtvec),  
    .ifu_req_valid (ifu_req_valid),
    .ifu_req_ready (ifu_req_ready),
    .ifu_req_pc    (ifu_req_pc   ),
    .ifu_req_seq     (ifu_req_seq     ),
    .ifu_req_seq_rv32(ifu_req_seq_rv32),
    .ifu_req_last_pc (ifu_req_last_pc ),
    .ifu_rsp_valid (ifu_rsp_valid),
    .ifu_rsp_ready (ifu_rsp_ready),
    .ifu_rsp_err   (ifu_rsp_err  ),
    .ifu_rsp_instr (ifu_rsp_instr[31:0]),
    .ifu_o_ir      (ifu_o_ir     ),
    .ifu_o_pc      (ifu_o_pc     ),
    .ifu_o_pc_vld  (ifu_o_pc_vld ),
    .ifu_o_misalgn (ifu_o_misalgn),
    .ifu_o_buserr  (ifu_o_buserr ),
    .ifu_o_rs1idx  (ifu_o_rs1idx),
    .ifu_o_rs2idx  (ifu_o_rs2idx),
    .ifu_o_prdt_taken(ifu_o_prdt_taken),
    .ifu_o_muldiv_b2b(ifu_o_muldiv_b2b),
    .ifu_o_valid   (ifu_o_valid  ),
    .ifu_o_ready   (ifu_o_ready  ),
    .pipe_flush_ack     (pipe_flush_ack    ), 
    .pipe_flush_req     (pipe_flush_req    ),
    .pipe_flush_add_op1 (pipe_flush_add_op1),     
    .pipe_flush_pc      (pipe_flush_pc),  
    .pipe_flush_add_op2 (pipe_flush_add_op2), 
    .ifu_halt_req  (ifu_halt_req ),
    .ifu_halt_ack  (ifu_halt_ack ),

    .oitf_empty    (oitf_empty   ),
    .rf2ifu_x1     (rf2ifu_x1    ),
    .rf2ifu_rs1    (rf2ifu_rs1   ),
    .dec2ifu_rden  (dec2ifu_rden ),
    .dec2ifu_rs1en (dec2ifu_rs1en),
    .dec2ifu_rdidx (dec2ifu_rdidx),
    .dec2ifu_mulhsu(dec2ifu_mulhsu),
    .dec2ifu_div   (dec2ifu_div   ),
    .dec2ifu_rem   (dec2ifu_rem   ),
    .dec2ifu_divu  (dec2ifu_divu  ),
    .dec2ifu_remu  (dec2ifu_remu  ),

    .clk           (clk          ),
    .rst_n         (rst_n        ) 
  );



  e203_ifu_ift2icb u_e203_ifu_ift2icb (
    .ifu_req_valid (ifu_req_valid),
    .ifu_req_ready (ifu_req_ready),
    .ifu_req_pc    (ifu_req_pc   ),
    .ifu_req_seq     (ifu_req_seq     ),
    .ifu_req_seq_rv32(ifu_req_seq_rv32),
    .ifu_req_last_pc (ifu_req_last_pc ),
    .ifu_rsp_valid (ifu_rsp_valid),
    .ifu_rsp_ready (ifu_rsp_ready),
    .ifu_rsp_err   (ifu_rsp_err  ),
    .ifu_rsp_instr (ifu_rsp_instr),
    .itcm_nohold   (itcm_nohold),

    .itcm_region_indic (itcm_region_indic),
    .ifu2itcm_icb_cmd_valid(ifu2itcm_icb_cmd_valid),
    .ifu2itcm_icb_cmd_ready(ifu2itcm_icb_cmd_ready),
    .ifu2itcm_icb_cmd_addr (ifu2itcm_icb_cmd_addr ),
    .ifu2itcm_icb_rsp_valid(ifu2itcm_icb_rsp_valid),
    .ifu2itcm_icb_rsp_ready(ifu2itcm_icb_rsp_ready),
    .ifu2itcm_icb_rsp_err  (ifu2itcm_icb_rsp_err  ),
    .ifu2itcm_icb_rsp_rdata(ifu2itcm_icb_rsp_rdata),

    .ifu2biu_icb_cmd_valid(ifu2biu_icb_cmd_valid),
    .ifu2biu_icb_cmd_ready(ifu2biu_icb_cmd_ready),
    .ifu2biu_icb_cmd_addr (ifu2biu_icb_cmd_addr ),
    .ifu2biu_icb_rsp_valid(ifu2biu_icb_rsp_valid),
    .ifu2biu_icb_rsp_ready(ifu2biu_icb_rsp_ready),
    .ifu2biu_icb_rsp_err  (ifu2biu_icb_rsp_err  ),
    .ifu2biu_icb_rsp_rdata(ifu2biu_icb_rsp_rdata),

    .ifu2itcm_holdup (ifu2itcm_holdup),

    .clk           (clk          ),
    .rst_n         (rst_n        ) 
  );

  assign ifu_active = 1'b1;// Seems the IFU never rest at block level
  
endmodule

