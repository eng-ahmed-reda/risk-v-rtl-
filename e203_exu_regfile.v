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
// Designer   : Bob Hu
//
// Description:
//  The Regfile module to implement the core's general purpose registers file
//
// ===================================================================

module e203_exu_regfile(
  input  [5-1:0] read_src1_idx,
  input  [5-1:0] read_src2_idx,
  output [32-1:0] read_src1_dat,
  output [32-1:0] read_src2_dat,

  input  wbck_dest_ena,
  input  wbck_dest_wen,
  input  [5-1:0] wbck_dest_idx,
  input  [32-1:0] wbck_dest_dat,

  output [32-1:0] x1_r,

  input  test_mode,
  input  clk,
  input  rst_n
  );

  wire [32-1:0] rf_r [32-1:0];
  wire [32-1:0] rf_wen;
  
  // Use DFF to buffer the write-port
  wire [32-1:0] wbck_dest_dat_r;
  sirv_gnrl_dffl #(32) wbck_dat_dffl (wbck_dest_ena, wbck_dest_dat, wbck_dest_dat_r, clk);
  wire [32-1:0] clk_rf_ltch;

  
  genvar i;
  generate //{
  
      for (i=0; i<32; i=i+1) begin:regfile//{
  
        if(i==0) begin: rf0
            // x0 cannot be wrote since it is constant-zeros
            assign rf_wen[i] = 1'b0;
            assign rf_r[i] = 32'b0;
            assign clk_rf_ltch[i] = 1'b0;
        end
        else begin: rfno0
            assign rf_wen[i] = wbck_dest_ena & (wbck_dest_idx == i) ;
            e203_clkgate u_e203_clkgate(
              .clk_in  (clk  ),
              .test_mode(test_mode),
              .clock_en(rf_wen[i]),
              .clk_out (clk_rf_ltch[i])
            );
                //from write-enable to clk_rf_ltch to rf_ltch
            sirv_gnrl_ltch #(32) rf_ltch (clk_rf_ltch[i], wbck_dest_dat_r, rf_r[i]);
        end
  
      end//}
  endgenerate//}
  
  assign read_src1_dat = rf_r[read_src1_idx];
  assign read_src2_dat = rf_r[read_src2_idx];
 
  assign x1_r = rf_r[1];
      
endmodule

