// System	
    input                         nice_clk            
    input                         nice_rst_n	          	  
//    output                        nice_rsp_err_irq	  
    // Control cmd_req
    input                         nice_req_valid  // cpu > core > excution >exu alu > exu_nice>
    //  assign nice_req_valid = ~nice_i_xs_off &  nice_req_valid_pos;
    //  wire   nice_req_valid_pos = nice_i_valid & nice_o_ready;
    //assign nice_o_ready      = o_sel_nice==nice_op & o_ready;
 //      wire nice_i_valid = i_valid & nice_op;
 //   i_valid=disp_i_valid_pos = disp_condition & disp_i_valid; at exu disp 
 //  disp_i_valid= ifu_o_valid  = ir_valid_r =  ir_valid_nxt  = ir_valid_set  | (~ir_valid_clr);;
  // The ir valid is set when there is new instruction fetched *and* 
     //   no flush happening 
      // The ir valid is cleared when it is accepted by EXU stage *or*
     //   the flush happening 
 // wire disp_condition = 
                 
 //                 (disp_csr ? oitf_empty : 1'b1)
 //                // To handle the Fence: just stall dispatch until the OITF is empt
 //               & (disp_fence_fencei ? oitf_empty : 1'b1)
 //                 // If it was a WFI instruction commited halt req, then it will stall the disaptch
 //               & (~wfi_halt_exu_req)   
 //                 // No dependency
 //               & (~dep)   
 //               ////  // If dispatch to ALU as long pipeline, then must check
 //               ////  //   the OITF is ready
 //               //// & ((disp_alu & disp_o_alu_longpipe) ? disp_oitf_ready : 1'b1);
 //               // To cut the critical timing  path from longpipe signal
 //               // we always assume the LSU will need oitf ready
 //               & (disp_alu_longp_prdt ? disp_oitf_ready : 1'b1);  
 //   wire nice_op = (~ifu_excp_op) & (i_info[3:0] == 4'd5); at exu alu 
 // wire ifu_excp_op = i_ilegl | i_buserr | i_misalgn;
 // i_info =disp_o_alu_info  = disp_i_info;
 // assign dec_info = 
 //              ({21{alu_op}}     & {{21-16{1'b0}},alu_info_bus})
 //            | ({21{amoldst_op}} & {{21-8{1'b0}},agu_info_bus})
 //            | ({21{bjp_op}}     & {{21-4{1'b0}},bjp_info_bus})
 //            | ({21{csr_op}}     & {{21-6{1'b0}},csr_info_bus})
 //            | ({21{muldiv_op}}  & {{21-3{1'b0}},muldiv_info_bus})
 //           `ifdef E203_HAS_NICE//{
 //            | ({21{nice_op}}     & {{21-2{1'b0}},nice_info_bus})
 //           `endif//}
 //              ;
 //  wire nice_op = rv32_custom0 | rv32_custom1 | rv32_custom2 | rv32_custom3;
// assign nice_info_bus[3:0    ]    = 4'd5;
  //assign nice_info_bus[4   ]    = rv32;
  //assign nice_info_bus[5]  = nice_instr;
 //wire rv32 = (~(i_instr[4:2] == 3'b111)) & opcode_1_0_11;
 // wire opcode_1_0_11  = (opcode[1:0] == 2'b11);

    output                        nice_req_ready       
    input  [32-1:0]       nice_req_inst 
    //assign nice_req_instr = nice_i_instr== cmt_o_instr   = i_instr ;  
     //wire [32-1:0] ifu_ir_nxt = ifu_rsp_instr;
    input  [32-1:0]       nice_req_rs1         
    input  [32-1:0]       nice_req_rs2         
    // Control cmd_rsp	
    output                        nice_rsp_valid       
    input                         nice_rsp_ready       
    output [32-1:0]       nice_rsp_rdat        
    output                        nice_rsp_err    	  
    // Memory lsu_req	
    output                        nice_icb_cmd_valid   
    input                         nice_icb_cmd_ready   
    output [32-1:0]  nice_icb_cmd_addr    
    output                        nice_icb_cmd_read    
    output [32-1:0]       nice_icb_cmd_wdata   
    output [4-1:0]     nice_icb_cmd_wmask,
    output [2-1:0]                  nice_icb_cmd_size    
    // Memory lsu_rsp	
    input                         nice_icb_rsp_valid   
    output                        nice_icb_rsp_ready   
    input  [32-1:0]       nice_icb_rsp_rdata   
    input                         nice_icb_rsp_err	