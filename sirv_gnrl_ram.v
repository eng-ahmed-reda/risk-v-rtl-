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
//  The top level RAM module
//
// ====================================================================

module sirv_gnrl_ram
#(parameter DP = 32,
  parameter DW = 32,
  parameter FORCE_X2ZERO = 1,
  parameter MW = 4,
  parameter AW = 15 
  ) (
  input            sd,
  input            ds,
  input            ls,

  input            rst_n,
  input            clk,
  input            cs,
  input            we,
  input [AW-1:0]   addr,
  input [DW-1:0]   din,
  input [MW-1:0]   wem,
  output reg [DW-1:0]   dout
);

reg [DW-1:0] mem [0:DP-1];

//To add the ASIC or FPGA or Sim-model control here
// This is the Sim-model
//
// Use ASIC/simulation RAM model
always @(posedge clk) begin
  if (we) mem[addr] <= din;
  dout <= mem[addr];
end

endmodule
