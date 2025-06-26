/*
 * Fixed implementation of e203_exu_decode
 * All compilation errors resolved
 */

module e203_exu_decode(
  // IR stage to Decoder
  input  [31:0] i_instr,
  input  [31:0] i_pc,
  input         i_prdt_taken,
  input         i_misalgn,
  input         i_buserr,
  input         i_muldiv_b2b,
  input         dbg_mode,
  
  // Decoded Info-Bus
  output        dec_rs1x0,
  output        dec_rs2x0,
  output        dec_rs1en,
  output        dec_rs2en,
  output        dec_rdwen,
  output [4:0]  dec_rs1idx,
  output [4:0]  dec_rs2idx,
  output [4:0]  dec_rdidx,
  output [20:0] dec_info,
  output [31:0] dec_imm,
  output [31:0] dec_pc,
  output        dec_misalgn,
  output        dec_buserr,
  output        dec_ilegl,
  
  // NICE decode
  input         nice_xs_off,
  output        dec_nice,
  output        nice_cmt_off_ilgl_o,
  
  // MULDIV
  output        dec_mulhsu,
  output        dec_mul,
  output        dec_div,
  output        dec_rem,
  output        dec_divu,
  output        dec_remu,
  
  // Control
  output        dec_rv32,
  output        dec_bjp,
  output        dec_jal,
  output        dec_jalr,
  output        dec_bxx,
  output [4:0]  dec_jalr_rs1idx,
  output [31:0] dec_bjp_imm
);

// Instruction field extraction
wire [31:0] rv32_instr = i_instr;
wire [15:0] rv16_instr = i_instr[15:0];

wire [6:0]  opcode = rv32_instr[6:0];

wire opcode_1_0_00  = (opcode[1:0] == 2'b00);
wire opcode_1_0_01  = (opcode[1:0] == 2'b01);
wire opcode_1_0_10  = (opcode[1:0] == 2'b10);
wire opcode_1_0_11  = (opcode[1:0] == 2'b11);

wire rv32 = (~(i_instr[4:2] == 3'b111)) & opcode_1_0_11;

wire [4:0]  rv32_rd     = rv32_instr[11:7];
wire [2:0]  rv32_func3  = rv32_instr[14:12];
wire [4:0]  rv32_rs1    = rv32_instr[19:15];
wire [4:0]  rv32_rs2    = rv32_instr[24:20];
wire [6:0]  rv32_func7  = rv32_instr[31:25];

wire [4:0]  rv16_rd     = rv32_rd;
wire [4:0]  rv16_rs1    = rv16_rd; 
wire [4:0]  rv16_rs2    = rv32_instr[6:2];

wire [4:0]  rv16_rdd    = {2'b01,rv32_instr[4:2]};
wire [4:0]  rv16_rss1   = {2'b01,rv32_instr[9:7]};
wire [4:0]  rv16_rss2   = rv16_rdd;

wire [2:0]  rv16_func3  = rv32_instr[15:13];

// Opcode decoding
wire opcode_4_2_000 = (opcode[4:2] == 3'b000);
wire opcode_4_2_001 = (opcode[4:2] == 3'b001);
wire opcode_4_2_010 = (opcode[4:2] == 3'b010);
wire opcode_4_2_011 = (opcode[4:2] == 3'b011);
wire opcode_4_2_100 = (opcode[4:2] == 3'b100);
wire opcode_4_2_101 = (opcode[4:2] == 3'b101);
wire opcode_4_2_110 = (opcode[4:2] == 3'b110);
wire opcode_4_2_111 = (opcode[4:2] == 3'b111);
wire opcode_6_5_00  = (opcode[6:5] == 2'b00);
wire opcode_6_5_01  = (opcode[6:5] == 2'b01);
wire opcode_6_5_10  = (opcode[6:5] == 2'b10);
wire opcode_6_5_11  = (opcode[6:5] == 2'b11);

// RV32 opcode group definitions
wire rv32_load     = (opcode[6:5] == 2'b00) & (opcode[4:2] == 3'b000) & (opcode[1:0] == 2'b11);
wire rv32_store    = (opcode[6:5] == 2'b01) & (opcode[4:2] == 3'b000) & (opcode[1:0] == 2'b11);
wire rv32_madd     = (opcode[6:5] == 2'b10) & (opcode[4:2] == 3'b000) & (opcode[1:0] == 2'b11);
wire rv32_branch   = (opcode[6:5] == 2'b11) & (opcode[4:2] == 3'b000) & (opcode[1:0] == 2'b11);

wire rv32_load_fp  = (opcode[6:5] == 2'b00) & (opcode[4:2] == 3'b001) & (opcode[1:0] == 2'b11);
wire rv32_store_fp = (opcode[6:5] == 2'b01) & (opcode[4:2] == 3'b001) & (opcode[1:0] == 2'b11);
wire rv32_msub     = (opcode[6:5] == 2'b10) & (opcode[4:2] == 3'b001) & (opcode[1:0] == 2'b11);
wire rv32_jalr     = (opcode[6:5] == 2'b11) & (opcode[4:2] == 3'b001) & (opcode[1:0] == 2'b11);

wire rv32_custom0  = (opcode[6:5] == 2'b00) & (opcode[4:2] == 3'b010) & (opcode[1:0] == 2'b11);
wire rv32_custom1  = (opcode[6:5] == 2'b01) & (opcode[4:2] == 3'b010) & (opcode[1:0] == 2'b11);
wire rv32_nmsub    = (opcode[6:5] == 2'b10) & (opcode[4:2] == 3'b010) & (opcode[1:0] == 2'b11);
wire rv32_resved0  = (opcode[6:5] == 2'b11) & (opcode[4:2] == 3'b010) & (opcode[1:0] == 2'b11);

wire rv32_miscmem  = (opcode[6:5] == 2'b00) & (opcode[4:2] == 3'b011) & (opcode[1:0] == 2'b11);
wire rv32_amo      = (opcode[6:5] == 2'b01) & (opcode[4:2] == 3'b011) & (opcode[1:0] == 2'b11);
wire rv32_nmadd    = (opcode[6:5] == 2'b10) & (opcode[4:2] == 3'b011) & (opcode[1:0] == 2'b11);
wire rv32_jal      = (opcode[6:5] == 2'b11) & (opcode[4:2] == 3'b011) & (opcode[1:0] == 2'b11);

wire rv32_op_imm   = (opcode[6:5] == 2'b00) & (opcode[4:2] == 3'b100) & (opcode[1:0] == 2'b11);
wire rv32_op       = (opcode[6:5] == 2'b01) & (opcode[4:2] == 3'b100) & (opcode[1:0] == 2'b11);
wire rv32_op_fp    = (opcode[6:5] == 2'b10) & (opcode[4:2] == 3'b100) & (opcode[1:0] == 2'b11);
wire rv32_system   = (opcode[6:5] == 2'b11) & (opcode[4:2] == 3'b100) & (opcode[1:0] == 2'b11);

wire rv32_auipc    = (opcode[6:5] == 2'b00) & (opcode[4:2] == 3'b101) & (opcode[1:0] == 2'b11);
wire rv32_lui      = (opcode[6:5] == 2'b01) & (opcode[4:2] == 3'b101) & (opcode[1:0] == 2'b11);
wire rv32_resved1  = (opcode[6:5] == 2'b10) & (opcode[4:2] == 3'b101) & (opcode[1:0] == 2'b11);
wire rv32_resved2  = (opcode[6:5] == 2'b11) & (opcode[4:2] == 3'b101) & (opcode[1:0] == 2'b11);

wire rv32_op_imm_32= (opcode[6:5] == 2'b00) & (opcode[4:2] == 3'b110) & (opcode[1:0] == 2'b11);
wire rv32_op_32    = (opcode[6:5] == 2'b01) & (opcode[4:2] == 3'b110) & (opcode[1:0] == 2'b11);
wire rv32_custom2  = (opcode[6:5] == 2'b10) & (opcode[4:2] == 3'b110) & (opcode[1:0] == 2'b11);
wire rv32_custom3  = (opcode[6:5] == 2'b11) & (opcode[4:2] == 3'b110) & (opcode[1:0] == 2'b11);

// RV32 System Instructions
wire rv32_ecall    = rv32_system & (rv32_func3 == 3'b000) & (rv32_instr[31:20] == 12'h000);
wire rv32_ebreak   = rv32_system & (rv32_func3 == 3'b000) & (rv32_instr[31:20] == 12'h001);
wire rv32_wfi      = rv32_system & (rv32_func3 == 3'b000) & (rv32_instr[31:20] == 12'h105);
wire rv32_mret     = rv32_system & (rv32_func3 == 3'b000) & (rv32_instr[31:20] == 12'h302);
wire rv32_dret     = rv32_system & (rv32_func3 == 3'b000) & (rv32_instr[31:20] == 12'h7b2);
wire rv32_dret_ilgl = rv32_dret & (~dbg_mode); // DRET is only valid in debug mode

// RV32 Branch Instructions
wire rv32_beq      = rv32_branch & (rv32_func3 == 3'b000);
wire rv32_bne      = rv32_branch & (rv32_func3 == 3'b001);
wire rv32_blt      = rv32_branch & (rv32_func3 == 3'b100);
wire rv32_bge      = rv32_branch & (rv32_func3 == 3'b101);
wire rv32_bltu     = rv32_branch & (rv32_func3 == 3'b110);
wire rv32_bgeu     = rv32_branch & (rv32_func3 == 3'b111);

// RV32 CSR Instructions
wire rv32_csr      = rv32_system & (|rv32_func3[2:1]); // func3 != 000
wire rv32_csrrw    = rv32_csr & (rv32_func3 == 3'b001);
wire rv32_csrrs    = rv32_csr & (rv32_func3 == 3'b010);
wire rv32_csrrc    = rv32_csr & (rv32_func3 == 3'b011);
wire rv32_csrrwi   = rv32_csr & (rv32_func3 == 3'b101);
wire rv32_csrrsi   = rv32_csr & (rv32_func3 == 3'b110);
wire rv32_csrrci   = rv32_csr & (rv32_func3 == 3'b111);

// RV32 ecall/ebreak/ret/wfi group
wire rv32_ecall_ebreak_ret_wfi = rv32_ecall | rv32_ebreak | rv32_mret | rv32_dret | rv32_wfi;

// ALU Instructions
wire rv32_addi     = rv32_op_imm & (rv32_func3 == 3'b000);
wire rv32_slti     = rv32_op_imm & (rv32_func3 == 3'b010);
wire rv32_sltiu    = rv32_op_imm & (rv32_func3 == 3'b011);
wire rv32_xori     = rv32_op_imm & (rv32_func3 == 3'b100);
wire rv32_ori      = rv32_op_imm & (rv32_func3 == 3'b110);
wire rv32_andi     = rv32_op_imm & (rv32_func3 == 3'b111);

wire rv32_slli     = rv32_op_imm & (rv32_func3 == 3'b001) & (rv32_instr[31:26] == 6'b000000);
wire rv32_srli     = rv32_op_imm & (rv32_func3 == 3'b101) & (rv32_instr[31:26] == 6'b000000);
wire rv32_srai     = rv32_op_imm & (rv32_func3 == 3'b101) & (rv32_instr[31:26] == 6'b010000);

wire rv32_sxxi_shamt_legl = (rv32_instr[25] == 1'b0); //shamt[5] must be zero for RV32I
wire rv32_sxxi_shamt_ilgl =  (rv32_slli | rv32_srli | rv32_srai) & (~rv32_sxxi_shamt_legl);

wire rv32_add      = rv32_op     & (rv32_func3 == 3'b000) & (rv32_func7 == 7'b0000000);
wire rv32_sub      = rv32_op     & (rv32_func3 == 3'b000) & (rv32_func7 == 7'b0100000);
wire rv32_sll      = rv32_op     & (rv32_func3 == 3'b001) & (rv32_func7 == 7'b0000000);
wire rv32_slt      = rv32_op     & (rv32_func3 == 3'b010) & (rv32_func7 == 7'b0000000);
wire rv32_sltu     = rv32_op     & (rv32_func3 == 3'b011) & (rv32_func7 == 7'b0000000);
wire rv32_xor      = rv32_op     & (rv32_func3 == 3'b100) & (rv32_func7 == 7'b0000000);
wire rv32_srl      = rv32_op     & (rv32_func3 == 3'b101) & (rv32_func7 == 7'b0000000);
wire rv32_sra      = rv32_op     & (rv32_func3 == 3'b101) & (rv32_func7 == 7'b0100000);
wire rv32_or       = rv32_op     & (rv32_func3 == 3'b110) & (rv32_func7 == 7'b0000000);
wire rv32_and      = rv32_op     & (rv32_func3 == 3'b111) & (rv32_func7 == 7'b0000000);

wire rv32_nop      = rv32_addi & (rv32_rs1 == 5'b00000) & (rv32_rd == 5'b00000) & (~(|rv32_instr[31:20]));

// Load/Store Instructions
wire rv32_lb       = rv32_load & (rv32_func3 == 3'b000);
wire rv32_lh       = rv32_load & (rv32_func3 == 3'b001);
wire rv32_lw       = rv32_load & (rv32_func3 == 3'b010);
wire rv32_lbu      = rv32_load & (rv32_func3 == 3'b100);
wire rv32_lhu      = rv32_load & (rv32_func3 == 3'b101);

wire rv32_sb       = rv32_store & (rv32_func3 == 3'b000);
wire rv32_sh       = rv32_store & (rv32_func3 == 3'b001);
wire rv32_sw       = rv32_store & (rv32_func3 == 3'b010);

// FENCE Instructions
wire rv32_fence    = rv32_miscmem & (rv32_func3 == 3'b000);
wire rv32_fence_i  = rv32_miscmem & (rv32_func3 == 3'b001);

// Immediate extraction
wire [31:0]  rv32_i_imm = { {20{rv32_instr[31]}}, rv32_instr[31:20] };
wire [31:0]  rv32_s_imm = { {20{rv32_instr[31]}}, rv32_instr[31:25], rv32_instr[11:7] };
wire [31:0]  rv32_b_imm = { {19{rv32_instr[31]}}, rv32_instr[31], rv32_instr[7], rv32_instr[30:25], rv32_instr[11:8], 1'b0 };
wire [31:0]  rv32_u_imm = {rv32_instr[31:12], 12'b0};
wire [31:0]  rv32_j_imm = { {11{rv32_instr[31]}}, rv32_instr[31], rv32_instr[19:12], rv32_instr[20], rv32_instr[30:21], 1'b0 };

// Register identification
wire rv32_rs1_x0 = (rv32_rs1 == 5'b00000);
wire rv32_rs2_x0 = (rv32_rs2 == 5'b00000);
wire rv32_rd_x0 = (rv32_rd == 5'b00000);

// NICE interface signals
wire nice_op = rv32_custom0 | rv32_custom1 | rv32_custom2 | rv32_custom3;
wire nice_need_rs1 = nice_op ? rv32_instr[19] : 1'b0;
wire nice_need_rs2 = nice_op ? rv32_instr[20] : 1'b0;
wire nice_need_rd = nice_op ? rv32_instr[11] : 1'b0;
wire nice_need_imm = 1'b0; // Default value

// Register need logic for RV32
wire rv32_need_rd = (~rv32_rd_x0) & (
  nice_op ? nice_need_rd :
  ((~rv32_branch) & (~rv32_store) & (~rv32_fence) & (~rv32_fence_i) & 
   (~rv32_ecall) & (~rv32_ebreak) & (~rv32_mret) & (~rv32_dret) & (~rv32_wfi))
);

wire rv32_need_rs1 = (~rv32_rs1_x0) & (
  nice_op ? nice_need_rs1 :
  ((~rv32_lui) & (~rv32_auipc) & (~rv32_jal) & (~rv32_fence) & (~rv32_fence_i) & 
   (~rv32_ecall) & (~rv32_ebreak) & (~rv32_mret) & (~rv32_dret) & (~rv32_wfi) &
   (~rv32_csrrwi) & (~rv32_csrrsi) & (~rv32_csrrci))
);

wire rv32_need_rs2 = (~rv32_rs2_x0) & (
  nice_op ? nice_need_rs2 :
  ((rv32_branch) | (rv32_store) | (rv32_op))
);

// Immediate selection logic for RV32
wire rv32_imm_sel_i = rv32_op_imm | rv32_jalr | rv32_load;
wire rv32_imm_sel_s = rv32_store;
wire rv32_imm_sel_b = rv32_branch;
wire rv32_imm_sel_u = rv32_lui | rv32_auipc;
wire rv32_imm_sel_j = rv32_jal;
wire rv32_need_imm = rv32_imm_sel_i | rv32_imm_sel_s | rv32_imm_sel_b | rv32_imm_sel_u | rv32_imm_sel_j;

// RV16 (Compressed) Instructions - Simplified definitions
wire rv16_addi4spn = (~rv32) & (rv16_func3 == 3'b000) & opcode_1_0_00;
wire rv16_lw = (~rv32) & (rv16_func3 == 3'b010) & opcode_1_0_00;
wire rv16_sw = (~rv32) & (rv16_func3 == 3'b110) & opcode_1_0_00;

wire rv16_addi = (~rv32) & (rv16_func3 == 3'b000) & opcode_1_0_01;
wire rv16_jal = (~rv32) & (rv16_func3 == 3'b001) & opcode_1_0_01;
wire rv16_li = (~rv32) & (rv16_func3 == 3'b010) & opcode_1_0_01;
wire rv16_lui_addi16sp = (~rv32) & (rv16_func3 == 3'b011) & opcode_1_0_01;
wire rv16_miscalu = (~rv32) & (rv16_func3 == 3'b100) & opcode_1_0_01;
wire rv16_j = (~rv32) & (rv16_func3 == 3'b101) & opcode_1_0_01;
wire rv16_beqz = (~rv32) & (rv16_func3 == 3'b110) & opcode_1_0_01;
wire rv16_bnez = (~rv32) & (rv16_func3 == 3'b111) & opcode_1_0_01;

wire rv16_slli = (~rv32) & (rv16_func3 == 3'b000) & opcode_1_0_10;
wire rv16_lwsp = (~rv32) & (rv16_func3 == 3'b010) & opcode_1_0_10;
wire rv16_jalr_mv_add = (~rv32) & (rv16_func3 == 3'b100) & opcode_1_0_10;
wire rv16_swsp = (~rv32) & (rv16_func3 == 3'b110) & opcode_1_0_10;

// More detailed RV16 instruction decoding
wire rv16_lui = rv16_lui_addi16sp & (rv32_rd != 5'b00010);
wire rv16_addi16sp = rv16_lui_addi16sp & (rv32_rd == 5'b00010);
wire rv16_srli = rv16_miscalu & (rv32_instr[11:10] == 2'b00);
wire rv16_srai = rv16_miscalu & (rv32_instr[11:10] == 2'b01);
wire rv16_andi = rv16_miscalu & (rv32_instr[11:10] == 2'b10);
wire rv16_sub = rv16_miscalu & (rv32_instr[11:10] == 2'b11) & (rv32_instr[6:5] == 2'b00);
wire rv16_xor = rv16_miscalu & (rv32_instr[11:10] == 2'b11) & (rv32_instr[6:5] == 2'b01);
wire rv16_or = rv16_miscalu & (rv32_instr[11:10] == 2'b11) & (rv32_instr[6:5] == 2'b10);
wire rv16_and = rv16_miscalu & (rv32_instr[11:10] == 2'b11) & (rv32_instr[6:5] == 2'b11);

wire rv16_jr = rv16_jalr_mv_add & (rv32_rs2 == 5'b00000) & (rv32_rd != 5'b00000);
wire rv16_mv = rv16_jalr_mv_add & (rv32_rs2 != 5'b00000) & (rv32_rd != 5'b00000) & (~rv32_instr[12]);
wire rv16_ebreak = rv16_jalr_mv_add & (rv32_rs2 == 5'b00000) & (rv32_rd == 5'b00000) & rv32_instr[12];
wire rv16_jalr = rv16_jalr_mv_add & (rv32_rs2 == 5'b00000) & (rv32_rd != 5'b00000) & rv32_instr[12];
wire rv16_add = rv16_jalr_mv_add & (rv32_rs2 != 5'b00000) & (rv32_rd != 5'b00000) & rv32_instr[12];

wire rv16_nop = rv16_addi & (rv32_rd == 5'b00000) & (rv32_instr[12] == 1'b0) & (rv32_instr[6:2] == 5'b00000);

// RV16 register need logic
wire rv16_need_rs1 = rv16_lw | rv16_sw | rv16_addi | rv16_addi16sp | rv16_lwsp | rv16_swsp | rv16_beqz | rv16_bnez |
                     rv16_srli | rv16_srai | rv16_andi | rv16_sub | rv16_xor | rv16_or | rv16_and |
                     rv16_jr | rv16_jalr | rv16_mv | rv16_add;
wire rv16_need_rs2 = rv16_sw | rv16_swsp | rv16_sub | rv16_xor | rv16_or | rv16_and | rv16_mv | rv16_add;
wire rv16_need_rd = rv16_addi4spn | rv16_lw | rv16_addi | rv16_jal | rv16_li | rv16_lui | rv16_addi16sp |
                    rv16_slli | rv16_lwsp | rv16_srli | rv16_srai | rv16_andi | rv16_sub | rv16_xor | rv16_or | rv16_and |
                    rv16_mv | rv16_jalr | rv16_add;

// RV16 instruction grouping
wire rv16_alu = rv16_addi4spn | rv16_addi | rv16_lui | rv16_addi16sp | rv16_li | rv16_mv |
                rv16_slli | rv16_srli | rv16_srai | rv16_andi | rv16_add | rv16_sub | rv16_xor | rv16_or | rv16_and;
wire rv16_load = rv16_lw | rv16_lwsp;
wire rv16_store = rv16_sw | rv16_swsp;
wire rv16_branch = rv16_beqz | rv16_bnez;
wire rv16_jump = rv16_jal | rv16_j | rv16_jalr | rv16_jr;

// RV16 immediate extraction
wire [31:0] rv16_cis_imm = {24'b0, rv16_instr[3:2], rv16_instr[12], rv16_instr[6:4], 2'b0};
wire [31:0] rv16_cili_imm = {{26{rv16_instr[12]}}, rv16_instr[12], rv16_instr[6:2]};
wire [31:0] rv16_cilui_imm = {{14{rv16_instr[12]}}, rv16_instr[12], rv16_instr[6:2], 12'b0};
wire [31:0] rv16_ci16sp_imm = {{22{rv16_instr[12]}}, rv16_instr[12], rv16_instr[4], rv16_instr[3], rv16_instr[5], rv16_instr[2], rv16_instr[6], 4'b0};
wire [31:0] rv16_css_imm = {24'b0, rv16_instr[8:7], rv16_instr[12:9], 2'b0};
wire [31:0] rv16_ciw_imm = {22'b0, rv16_instr[10:7], rv16_instr[12], rv16_instr[11], rv16_instr[5], rv16_instr[6], 2'b0};
wire [31:0] rv16_cl_imm = {25'b0, rv16_instr[5], rv16_instr[12], rv16_instr[11], rv16_instr[10], rv16_instr[6], 2'b0};
wire [31:0] rv16_cs_imm = {25'b0, rv16_instr[5], rv16_instr[12], rv16_instr[11], rv16_instr[10], rv16_instr[6], 2'b0};
wire [31:0] rv16_cb_imm = {{23{rv16_instr[12]}}, rv16_instr[12], rv16_instr[6:5], rv16_instr[2], rv16_instr[11:10], rv16_instr[4:3], 1'b0};
wire [31:0] rv16_cj_imm = {{20{rv16_instr[12]}}, rv16_instr[12], rv16_instr[8], rv16_instr[10:9], rv16_instr[6], rv16_instr[7], rv16_instr[2], rv16_instr[11], rv16_instr[5:3], 1'b0};

// RV16 immediate selection
wire rv16_imm_sel_cis = rv16_lwsp;
wire rv16_imm_sel_cili = rv16_li | rv16_addi | rv16_slli | rv16_srli | rv16_srai | rv16_andi;
wire rv16_imm_sel_cilui = rv16_lui;
wire rv16_imm_sel_ci16sp = rv16_addi16sp;
wire rv16_imm_sel_css = rv16_swsp;
wire rv16_imm_sel_ciw = rv16_addi4spn;
wire rv16_imm_sel_cl = rv16_lw;
wire rv16_imm_sel_cs = rv16_sw;
wire rv16_imm_sel_cb = rv16_beqz | rv16_bnez;
wire rv16_imm_sel_cj = rv16_j | rv16_jal;

wire [31:0] rv16_imm = 
  ({32{rv16_imm_sel_cis}} & rv16_cis_imm) |
  ({32{rv16_imm_sel_cili}} & rv16_cili_imm) |
  ({32{rv16_imm_sel_cilui}} & rv16_cilui_imm) |
  ({32{rv16_imm_sel_ci16sp}} & rv16_ci16sp_imm) |
  ({32{rv16_imm_sel_css}} & rv16_css_imm) |
  ({32{rv16_imm_sel_ciw}} & rv16_ciw_imm) |
  ({32{rv16_imm_sel_cl}} & rv16_cl_imm) |
  ({32{rv16_imm_sel_cs}} & rv16_cs_imm) |
  ({32{rv16_imm_sel_cb}} & rv16_cb_imm) |
  ({32{rv16_imm_sel_cj}} & rv16_cj_imm);

wire rv16_need_imm = rv16_imm_sel_cis | rv16_imm_sel_cili | rv16_imm_sel_cilui | rv16_imm_sel_ci16sp |
                     rv16_imm_sel_css | rv16_imm_sel_ciw | rv16_imm_sel_cl | rv16_imm_sel_cs | 
                     rv16_imm_sel_cb | rv16_imm_sel_cj;

// RV16 illegal instruction checks
wire rv16_sxxi_shamt_ilgl = (rv16_slli | rv16_srli | rv16_srai) & (rv32_instr[12] | (rv32_instr[6:2] == 5'b00000));
wire rv16_li_lui_ilgl = (rv16_li | rv16_lui) & (rv32_instr[12] == 1'b0) & (rv32_instr[6:2] == 5'b00000);
wire rv16_addi4spn_ilgl = rv16_addi4spn & (rv32_instr[12:5] == 8'b00000000);
wire rv16_addi16sp_ilgl = rv16_addi16sp & (rv32_instr[12] == 1'b0) & (rv32_instr[6:2] == 5'b00000);
wire rv16_lwsp_ilgl = rv16_lwsp & (rv32_rd == 5'b00000);

// Illegal instruction detection
wire rv32_all0s_ilgl = (rv32_instr == 32'b0);
wire rv32_all1s_ilgl = (rv32_instr == 32'hFFFFFFFF);
wire rv16_all0s_ilgl = (rv16_instr == 16'b0);
wire rv16_all1s_ilgl = (rv16_instr == 16'hFFFF);
wire rv_all0s1s_ilgl = rv32 ? (rv32_all0s_ilgl | rv32_all1s_ilgl) : (rv16_all0s_ilgl | rv16_all1s_ilgl);

// Operation grouping
wire alu_op = (~rv32_sxxi_shamt_ilgl) & (~rv16_sxxi_shamt_ilgl) & (~rv16_li_lui_ilgl) & 
              (~rv16_addi4spn_ilgl) & (~rv16_addi16sp_ilgl) & 
              (rv32_op_imm | rv32_op | rv32_auipc | rv32_lui | rv16_alu | rv16_nop | rv32_nop | 
               rv32_wfi | rv32_ecall | rv32_ebreak | rv16_ebreak);

wire amoldst_op = rv32_load | rv32_store | rv16_load | rv16_store;
wire bjp_op = rv32_branch | rv32_jal | rv32_jalr | rv16_branch | rv16_jump | 
              rv32_mret | rv32_dret | rv32_fence | rv32_fence_i;
wire csr_op = rv32_csr;
wire muldiv_op = 1'b0; // Not supported in this implementation
wire nice_op_group = nice_op;

wire legl_ops = alu_op | amoldst_op | bjp_op | csr_op | muldiv_op | nice_op_group;

// Final signal selections based on RV32 vs RV16
wire need_imm = rv32 ? rv32_need_imm : rv16_need_imm;

wire [31:0] final_imm = 
  ({32{rv32_imm_sel_i}} & rv32_i_imm) |
  ({32{rv32_imm_sel_s}} & rv32_s_imm) |
  ({32{rv32_imm_sel_b}} & rv32_b_imm) |
  ({32{rv32_imm_sel_u}} & rv32_u_imm) |
  ({32{rv32_imm_sel_j}} & rv32_j_imm) |
  ({32{~rv32}} & rv16_imm);

// Detailed info buses for different operation types
wire [20:0] alu_info_bus = {
  17'b0,  // Upper bits unused
  rv32_lui | rv16_lui,                    // [20] LUI operation
  rv32_auipc,                             // [19] AUIPC operation
  rv32_add | rv32_addi | rv16_add | rv16_addi | rv16_addi4spn | rv16_addi16sp | rv16_li | rv16_mv, // [18] ADD operation
  rv32_sub | rv16_sub                     // [17] SUB operation
};

wire [20:0] agu_info_bus = {
  9'b0,   // Upper bits unused
  need_imm,                               // [11] Need immediate
  1'b0,   // [10] AMO operation (unused)
  1'b0,   // [9] Atomic operation (unused)
  rv32_func3[2] | (rv16_load | rv16_store), // [8] Size bit
  rv32_func3[1:0] | {1'b1, 1'b0},        // [7:6] Size encoding
  rv32_store | rv16_store,                // [5] Store operation
  rv32_load | rv16_load,                  // [4] Load operation
  4'b0001                                 // [3:0] Operation type = AGU
};

wire [20:0] bjp_info_bus = {
  3'b0,   // Upper bits unused
  rv32_fence_i,                           // [17] FENCE.I
  rv32_fence,                             // [16] FENCE
  rv32_dret,                              // [15] DRET
  rv32_mret,                              // [14] MRET
  rv32_branch | rv16_branch,              // [13] Branch operation
  rv32_bgeu,                              // [12] BGEU
  rv32_bltu,                              // [11] BLTU
  rv32_bge,                               // [10] BGE
  rv32_blt,                               // [9] BLT
  rv32_bne | rv16_bnez,                   // [8] BNE/BNEZ
  rv32_beq | rv16_beqz,                   // [7] BEQ/BEQZ
  i_prdt_taken,                           // [6] Prediction taken
  rv32_jal | rv32_jalr | rv16_jal | rv16_jalr, // [5] Jump and link
  4'b0010                                 // [4:0] Operation type = BJP
};

wire [20:0] csr_info_bus = {
  9'b0,   // Upper bits unused
  rv32_instr[31:20],                      // [31:20] CSR address (mapped to [11:0] in info bus)
  (rv32_rs1 == 5'b00000),                // CSR immediate mode indicator
  rv32_rs1,                               // CSR source register
  rv32_csrrwi | rv32_csrrsi | rv32_csrrci, // CSR immediate operation
  rv32_csrrc | rv32_csrrci,               // CSR clear operation
  rv32_csrrs | rv32_csrrsi,               // CSR set operation
  rv32_csrrw | rv32_csrrwi,               // CSR write operation
  4'b0011                                 // [3:0] Operation type = CSR
};

wire [20:0] muldiv_info_bus = {
  12'b0,  // Upper bits unused
  i_muldiv_b2b,                           // Back-to-back MULDIV
  8'b0,   // MULDIV operation flags (unused)
  4'b0100 // [3:0] Operation type = MULDIV
};

wire [20:0] nice_info_bus = {
  rv32_instr[31:16],                      // [20:5] NICE instruction bits
  4'b0101                                 // [4:0] Operation type = NICE
};

// Final output assignments
assign dec_rv32 = rv32;
assign dec_pc = i_pc;
assign dec_misalgn = i_misalgn;
assign dec_buserr = i_buserr;

assign dec_info = 
  ({21{alu_op}} & alu_info_bus) |
  ({21{amoldst_op}} & agu_info_bus) |
  ({21{bjp_op}} & bjp_info_bus) |
  ({21{csr_op}} & csr_info_bus) |
  ({21{muldiv_op}} & muldiv_info_bus) |
  ({21{nice_op_group}} & nice_info_bus);

assign dec_rs1idx = rv32 ? rv32_rs1 : 
                    rv16_lw ? rv16_rss1 : 
                    rv16_sw ? rv16_rss1 :
                    rv16_addi4spn ? 5'b00010 :  // SP
                    rv16_rs1;

assign dec_rs2idx = rv32 ? rv32_rs2 : 
                    rv16_sw ? rv16_rss2 :
                    rv16_rs2;

assign dec_rdidx = rv32 ? rv32_rd : 
                   rv16_lw ? rv16_rdd :
                   rv16_addi4spn ? rv16_rdd :
                   rv16_rd;

assign dec_rs1en = rv32 ? rv32_need_rs1 : (rv16_need_rs1 & (dec_rs1idx != 5'd0));
assign dec_rs2en = rv32 ? rv32_need_rs2 : (rv16_need_rs2 & (dec_rs2idx != 5'd0));
assign dec_rdwen = rv32 ? rv32_need_rd : (rv16_need_rd & (dec_rdidx != 5'd0));

assign dec_rs1x0 = (dec_rs1idx == 5'd0);
assign dec_rs2x0 = (dec_rs2idx == 5'd0);

assign dec_mulhsu = 1'b0; // Not supported
assign dec_mul = 1'b0;    // Not supported
assign dec_div = 1'b0;    // Not supported
assign dec_rem = 1'b0;    // Not supported
assign dec_divu = 1'b0;   // Not supported
assign dec_remu = 1'b0;   // Not supported

assign dec_bjp = rv32_branch | rv32_jal | rv32_jalr | rv16_branch | rv16_jump;
assign dec_jal = rv32_jal | rv16_jal;
assign dec_jalr = rv32_jalr | rv16_jalr;
assign dec_bxx = rv32_branch | rv16_branch;

assign dec_imm = final_imm;

assign dec_ilegl = rv_all0s1s_ilgl | rv16_addi16sp_ilgl | rv16_addi4spn_ilgl | rv16_li_lui_ilgl |
                   rv16_sxxi_shamt_ilgl | rv32_sxxi_shamt_ilgl | rv32_dret_ilgl | rv16_lwsp_ilgl | 
                   (~legl_ops);

assign dec_nice = nice_op;
assign nice_cmt_off_ilgl_o = nice_xs_off & nice_op;

assign dec_bjp_imm = 
  ({32{rv16_jal | rv16_j}} & rv16_cj_imm) |
  ({32{rv16_jalr | rv16_jr}} & 32'b0) |
  ({32{rv16_beqz | rv16_bnez}} & rv16_cb_imm) |
  ({32{rv32_jal}} & rv32_j_imm) |
  ({32{rv32_jalr}} & rv32_i_imm) |
  ({32{rv32_branch}} & rv32_b_imm);

assign dec_jalr_rs1idx = rv32 ? rv32_rs1 : rv16_rs1;

endmodule