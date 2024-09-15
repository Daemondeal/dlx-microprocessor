set top "/tb_dlx"
set dlx "$top/DUT"
set cu "$dlx/CU_Instance"
set ms "$dlx/MS_Instance"
set dp "$dlx/DP_Instance"
set ic "$ms/ICache"
set dc "$ms/DCache"
set memory "$top/DUT_Memory"

delete wave *

add wave $top/wb_clk
add wave $top/wb_rst

add wave -expand -group Pipeline -hex $dp/reg_if_pc
add wave -expand -group Pipeline -hex -label "I\$ Hit" $ic/o_hit
add wave -expand -group Pipeline -hex -label "D\$ Hit" $dc/o_hit
add wave -expand -group Pipeline -unsigned $cu/s_debug_*
add wave -expand -group Pipeline -hex $dp/o_mm_btb_mispredict
add wave -expand -group Pipeline -hex $dp/o_if_btb_predict_will_branch

add wave -group "Wishbone Bus" -hex $top/wb_*

add wave -group Hazards $cu/s_*_stall
add wave -group Hazards $cu/s_*_flush

# add wave -group Datapath -group Fetch -hex $dp/i_if_cw

add wave -group Datapath -group BTB -hex $dp/s_if_btb_predicted_address
add wave -group Datapath -group BTB -hex $dp/s_if_npc

add wave -group Datapath -group BTB -hex $dp/reg_mm_npc
add wave -group Datapath -group BTB -hex $dp/s_if_btb_predicted_address
add wave -group Datapath -group BTB -hex $dp/s_if_btb_write_enable
add wave -group Datapath -group BTB -hex $dp/o_if_btb_predict_will_branch

add wave -group Datapath -group BTB -hex $dp/reg_mm_branch_taken
add wave -group Datapath -group BTB -hex $dp/o_mm_btb_mispredict

add wave -group Datapath -group BTB -group Internal -hex $dp/BranchPredictor/*

add wave -group Datapath -group Fetch -hex $dp/i_if_sel_pc_btb_npc_n

add wave -group Datapath -group Fetch -hex $dp/reg_if_pc
add wave -group Datapath -group Fetch -hex $dp/reg_if_pc_next

add wave -group Datapath -group Fetch -hex -group "IF/ID" $dp/reg_id_*_next


add wave -group Datapath -group Decode -hex -label "ID Control Word" $dp/i_id_cw

add wave -group Datapath -group Decode -hex $dp/reg_id_ir
add wave -group Datapath -group Decode -hex $dp/reg_id_npc

add wave -group Datapath -group Decode -unsigned -label "Register Source 1" $dp/s_id_rs1
add wave -group Datapath -group Decode -unsigned -label "Register Source 2" $dp/s_id_rs2
add wave -group Datapath -group Decode -unsigned -label "Register Destination" $dp/s_id_rd


add wave -group Datapath -group Decode -hex -group "ID/EX" $dp/reg_ex_*_next

add wave -group Datapath -group Execute -hex -label "EX Control Word" $dp/i_ex_cw
add wave -group Datapath -group Execute -hex $dp/i_ex_forward_*

add wave -group Datapath -group Execute -hex $dp/s_ex_forwarded_a
add wave -group Datapath -group Execute -hex $dp/s_ex_forwarded_b
add wave -group Datapath -group Execute -hex $dp/reg_ex_imm

add wave -group Datapath -group Execute -group ALU -hex $dp/AluInstance/i_*
add wave -group Datapath -group Execute -group ALU -hex $dp/AluInstance/o_*

add wave -group Datapath -group Execute -group Multiplier -hex $dp/Execute_Multicycle/unit_Mult/*
add wave -group Datapath -group Execute -group Multiplier -group Booth -hex $dp/Execute_Multicycle/unit_Mult/inst_BoothMul/*

add wave -group Datapath -group Execute -group Divider -hex $dp/Execute_Multicycle/unit_Div/i_*
add wave -group Datapath -group Execute -group Divider -hex $dp/Execute_Multicycle/unit_Div/o_*

add wave -group Datapath -group Execute -hex -group "EX/MM" $dp/reg_mm_*_next


add wave -group Datapath -group Memory -hex -label "MM Control Word" $dp/i_mm_cw

add wave -group Datapath -group Memory -group LSU -hex $dp/LSU/i_*
add wave -group Datapath -group Memory -group LSU -hex $dp/LSU/o_*

add wave -group Datapath -group Memory -hex -group "MM/WB" $dp/reg_wb_*_next

add wave -group Datapath -group WriteBack -hex -label "WB Control Word" $dp/i_wb_cw
add wave -group Datapath -group WriteBack -hex -label "RF Write Data" $dp/s_wb_rf_input
add wave -group Datapath -group WriteBack -hex -label "RF Write Register" $dp/s_wb_rf_rd
add wave -group Datapath -group WriteBack -hex -label "RF Write Enable" $dp/RegisterFileInstance/write_enable


add wave -group ICache -hex $ic/i_request_addr
add wave -group ICache -hex $ic/i_rd_request
add wave -group ICache -hex $ic/o_data_out
add wave -group ICache -hex $ic/o_hit
add wave -group ICache -hex $ic/state
add wave -group ICache -group MemoryRead -hex $ic/o_addr_to_mem
add wave -group ICache -group MemoryRead -hex $ic/o_mem_rd_request
add wave -group ICache -group MemoryRead -hex $ic/i_data_from_mem
add wave -group ICache -group MemoryRead -hex $ic/i_data_from_mem_valid
add wave -group ICache -group MissLogic -hex $ic/sets
add wave -group ICache -group MissLogic -unsigned $ic/input_set
add wave -group ICache -group MissLogic -hex $ic/input_tag
add wave -group ICache -group MissLogic -unsigned $ic/input_word
add wave -group ICache -group MissLogic -unsigned $ic/next_victims


add wave -group DCache -hex $dc/i_request_addr
add wave -group DCache -hex $dc/i_rd_request
add wave -group DCache -hex $dc/i_wr_request
add wave -group DCache -hex $dc/i_wr_data
add wave -group DCache -hex $dc/i_wr_data_sel
add wave -group DCache -hex $dc/o_data_out
add wave -group DCache -hex $dc/o_hit
add wave -group DCache -hex $dc/state
add wave -group DCache -group MemoryRead -hex $dc/o_addr_to_mem
add wave -group DCache -group MemoryRead -hex $dc/o_mem_rd_request
add wave -group DCache -group MemoryRead -hex $dc/i_data_from_mem
add wave -group DCache -group MemoryRead -hex $dc/i_data_from_mem_valid
add wave -group DCache -group MemoryWrite -hex $dc/o_mem_wr_request
add wave -group DCache -group MemoryWrite -hex $dc/i_mem_wr_done
add wave -group DCache -group MemoryWrite -hex $dc/o_mem_wr_data
add wave -group DCache -group MissLogic -hex $dc/sets
add wave -group DCache -group MissLogic -unsigned $dc/input_set
add wave -group DCache -group MissLogic -hex $dc/input_tag
add wave -group DCache -group MissLogic -unsigned $dc/input_word
add wave -group DCache -group MissLogic -unsigned $dc/next_victims

add wave -hex $dp/RegisterFileInstance/registers
;# NOTE: THIS IS VERY LARGE
;# add wave -hex $memory/memory
