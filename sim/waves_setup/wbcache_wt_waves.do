set top "/tb_writethroughcache"
set dut "$top/DUT"

delete wave *

add wave "$top/clk"
add wave "$top/rst_n"

add wave -divider "Memory"

add wave -hex fake_memory
add wave -hex mirror_memory
add wave -hex $top/o_addr_to_mem

add wave $top/o_mem_rd_request
add wave -hex $top/i_data_from_mem
add wave $top/i_data_from_mem_valid

add wave $top/o_mem_wr_request
add wave -hex $top/o_dataout_to_mem
add wave $top/i_mem_wr_done

add wave -divider "Read"

add wave $top/i_rd_request
add wave -hex $top/i_request_addr
add wave $top/o_hit
add wave $top/o_busy
add wave -hex $top/o_data_out

add wave -bin $dut/valid_bits

add wave -divider "Write"

add wave $top/i_wr_request
add wave -hex $top/i_request_addr
add wave -hex $top/i_datain_from_cpu
add wave $top/o_hit
add wave $top/o_busy

add wave -divider "Pseudo LRU"

add wave -bin $dut/pseudo_lru_state
add wave -unsigned $dut/next_victim

add wave -divider "Internal State"

add wave $dut/state
add wave $dut/state_next
add wave $dut/reg_wc_count
add wave $dut/wc_terminal_count

add wave -divider "Miss"

add wave -hex $top/o_addr_to_mem
add wave $top/o_mem_rd_request
add wave -hex $top/i_data_from_mem
add wave $top/i_data_from_mem_valid

add wave -hex $dut/req_addr_tag
add wave -hex $dut/tags
add wave -bin $dut/valid_bits

add wave -divider "Write Through"

add wave $dut/state
add wave $top/o_mem_wr_request
add wave -hex $top/o_dataout_to_mem
add wave -hex $dut/o_addr_to_mem
add wave $top/i_mem_wr_done

add wave -hex $dut/reg_out_cacheline_index
add wave -hex $dut/reg_out_word_index
add wave -hex $dut/reg_wc_count

add wave -hex $dut/next_victim
add wave -hex $dut/tags

add wave -bin $dut/valid_bits
add wave -hex $dut/cache_mem
