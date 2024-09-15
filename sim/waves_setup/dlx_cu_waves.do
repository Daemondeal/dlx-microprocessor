set TOP "/tb_dlx"

delete wave *

add wave "$TOP/clk"
add wave "$TOP/rst_n"

add wave -hex "$TOP/current_instruction"

add wave -divider "Fetch"
add wave "$TOP/pc_write_n"
add wave "$TOP/DUT_DP/npc_write_n"
add wave "$TOP/DUT_DP/ir_write_n"

add wave -divider "Decode"
add wave "$TOP/a_write_n"
add wave "$TOP/b_write_n"
add wave "$TOP/imm_write_n"
add wave "$TOP/rf_enable_n"
add wave "$TOP/ir_type"

add wave -hex "$TOP/DUT_DP/ir_i_rs1"
add wave -hex "$TOP/DUT_DP/ir_i_rd"
add wave -hex "$TOP/DUT_DP/ir_i_imm"

add wave -hex "$TOP/DUT_DP/reg_b_next"

add wave -divider "Execute"
add wave -binary "$TOP/DUT_CU/cw_ex"
add wave "$TOP/alu_op"
add wave "$TOP/alu_op"
add wave "$TOP/sel_alu_in1_a_npcn"
add wave "$TOP/sel_alu_in2_imm_bn"
add wave "$TOP/jump_condition"

add wave -hex "$TOP/DUT_DP/reg_rf_addr_in_dc"
add wave -hex "$TOP/DUT_DP/reg_b"

add wave -divider "Memory"
add wave -binary "$TOP/DUT_CU/cw_mm"
add wave "$TOP/mem_enable"
add wave "$TOP/mem_write_n"

add wave -hex "$TOP/DUT_DP/reg_rf_addr_in_ex"
add wave -hex "$TOP/DUT_DP/reg_alu_out"
add wave -hex "$TOP/DUT_DP/reg_b_ex"

add wave -divider "WriteBack"
add wave -binary "$TOP/DUT_CU/cw_wb"
add wave "$TOP/wb_mem_alun"
add wave "$TOP/rf_write"

add wave "$TOP/DUT_DP/reg_rf_addr_in_mm"
add wave "$TOP/DUT_DP/reg_alu_out_mm"
add wave "$TOP/DUT_DP/rf_input"

add wave "$TOP/DUT_DP/reg_alu_out_mm"

add wave -divider "Debug"
add wave "$TOP/DUT_DP/RegFile/registers(5)"
