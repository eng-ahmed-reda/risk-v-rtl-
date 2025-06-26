// Copyright 2017 ETH Zurich and University of Bologna.
// -- Adaptable modifications made for hbirdv2 SoC. -- 
// Copyright 2020 Nuclei System Technology, Inc.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module spi_master_apb_if
#(
    parameter BUFFER_DEPTH   = 10,
    parameter APB_ADDR_WIDTH = 12,  //APB slaves are 4KB by default
    parameter LOG_BUFFER_DEPTH = 4  // log2(BUFFER_DEPTH) = log2(10) = 4
)
(
    input  wire                        HCLK,
    input  wire                        HRESETn,
    input  wire [APB_ADDR_WIDTH - 1:0] PADDR,
    input  wire [31:0]                 PWDATA,
    input  wire                        PWRITE,
    input  wire                        PSEL,
    input  wire                        PENABLE,
    output reg  [31:0]                 PRDATA,
    output wire                        PREADY,
    output wire                        PSLVERR,

    output reg  [7:0]                  spi_clk_div,
    output reg                         spi_clk_div_valid,
    input  wire [31:0]                 spi_status,
    output reg  [31:0]                 spi_addr,
    output reg  [5:0]                  spi_addr_len,
    output reg  [31:0]                 spi_cmd,
    output reg  [5:0]                  spi_cmd_len,
    output reg  [3:0]                  spi_csreg,
    output reg  [15:0]                 spi_data_len,
    output reg  [15:0]                 spi_dummy_rd,
    output reg  [15:0]                 spi_dummy_wr,
    output reg  [LOG_BUFFER_DEPTH:0]   spi_int_th_tx,
    output reg  [LOG_BUFFER_DEPTH:0]   spi_int_th_rx,
    output reg                         spi_int_en,
    input  wire [31:0]                 spi_int_status,
    output reg                         spi_swrst,
    output reg                         spi_rd,
    output reg                         spi_wr,
    output reg                         spi_qrd,
    output reg                         spi_qwr,
    output wire [31:0]                 spi_data_tx,
    output wire                        spi_data_tx_valid,
    input  wire                        spi_data_tx_ready,
    input  wire [31:0]                 spi_data_rx,
    input  wire                        spi_data_rx_valid,
    output wire                        spi_data_rx_ready
);

    wire [3:0] write_address;
    wire [3:0] read_address;
    
    assign write_address = PADDR[5:2];
    assign read_address  = PADDR[5:2];
    
    assign PSLVERR = 1'b0;
    assign PREADY  = 1'b1;
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (HRESETn == 1'b0) begin
            spi_swrst         <= 1'b0;
            spi_rd            <= 1'b0;
            spi_wr            <= 1'b0;
            spi_qrd           <= 1'b0;
            spi_qwr           <= 1'b0;
            spi_clk_div_valid <= 1'b0;
            spi_clk_div       <= 'b0;
            spi_cmd           <= 'b0;
            spi_addr          <= 'b0;
            spi_cmd_len       <= 'b0;
            spi_addr_len      <= 'b0;
            spi_data_len      <= 'b0;
            spi_dummy_rd      <= 'b0;
            spi_dummy_wr      <= 'b0;
            spi_csreg         <= 'b0;
            spi_int_th_tx     <= 'b0;
            spi_int_th_rx     <= 'b0;
            spi_int_en        <= 1'b0;
	end else if (PSEL && PENABLE && PWRITE) begin
            spi_swrst         <= 1'b0;
            spi_rd            <= 1'b0;
            spi_wr            <= 1'b0;
            spi_qrd           <= 1'b0;
            spi_qwr           <= 1'b0;
            spi_clk_div_valid <= 1'b0;

            case (write_address)
                4'b0000: begin  // REG_STATUS
                    spi_rd    <= PWDATA[0];
                    spi_wr    <= PWDATA[1];
                    spi_qrd   <= PWDATA[2];
                    spi_qwr   <= PWDATA[3];
                    spi_swrst <= PWDATA[4];
                    spi_csreg <= PWDATA[11:8];
                end
                4'b0001: begin  // REG_CLKDIV
                    spi_clk_div       <= PWDATA[7:0];
                    spi_clk_div_valid <= 1'b1;
                end
                4'b0010: spi_cmd  <= PWDATA;  // REG_SPICMD
                4'b0011: spi_addr <= PWDATA;  // REG_SPIADR
                4'b0100: begin  // REG_SPILEN
                    spi_cmd_len        <= PWDATA[5:0];
                    spi_addr_len       <= PWDATA[13:8];
                    spi_data_len[7:0]  <= PWDATA[23:16];
                    spi_data_len[15:8] <= PWDATA[31:24];
                end
                4'b0101: begin  // REG_SPIDUM
                    spi_dummy_rd[7:0]  <= PWDATA[7:0];
                    spi_dummy_rd[15:8] <= PWDATA[15:8];
                    spi_dummy_wr[7:0]  <= PWDATA[23:16];
                    spi_dummy_wr[15:8] <= PWDATA[31:24];
                end
                4'b1001: begin  // REG_INTCFG
                    spi_int_th_tx <= PWDATA[LOG_BUFFER_DEPTH:0];
                    spi_int_th_rx <= PWDATA[8 + LOG_BUFFER_DEPTH:8];
                    spi_int_en    <= PWDATA[31];
                end
            endcase
	end else begin
            spi_swrst         <= 1'b0;
            spi_rd            <= 1'b0;
            spi_wr            <= 1'b0;
            spi_qrd           <= 1'b0;
            spi_qwr           <= 1'b0;
            spi_clk_div_valid <= 1'b0;
        end
    end  // SLAVE_REG_WRITE_PROC
    
    
    // implement slave model register read mux
    always @(*) begin
        case (read_address)
            4'b0000: PRDATA = spi_status;  // REG_STATUS
            4'b0001: PRDATA = {24'h0, spi_clk_div};  // REG_CLKDIV
            4'b0010: PRDATA = spi_cmd;  // REG_SPICMD
            4'b0011: PRDATA = spi_addr;  // REG_SPIADR
            4'b0100: PRDATA = {spi_data_len, 2'b00, spi_addr_len, 2'b00, spi_cmd_len};  // REG_SPILEN
            4'b0101: PRDATA = {spi_dummy_wr, spi_dummy_rd};  // REG_SPIDUM
            4'b1000: PRDATA = spi_data_rx;  // REG_RXFIFO
            4'b1001: begin  // REG_INTCFG
                PRDATA                         = 'b0;
                PRDATA[LOG_BUFFER_DEPTH:0]     = spi_int_th_tx;
                PRDATA[8 + LOG_BUFFER_DEPTH:8] = spi_int_th_rx;
                PRDATA[31]                     = spi_int_en;
            end
            4'b1010: PRDATA = spi_int_status;  // REG_INTSTA
            default: PRDATA = 'b0;
        endcase
    end    // SLAVE_REG_READ_PROC

    assign spi_data_tx       = PWDATA;
    assign spi_data_tx_valid = ((PSEL & PENABLE) & PWRITE) & (write_address == 4'b0110);  // REG_TXFIFO
    assign spi_data_rx_ready = ((PSEL & PENABLE) & ~PWRITE) & (read_address == 4'b1000);  // REG_RXFIFO


endmodule
