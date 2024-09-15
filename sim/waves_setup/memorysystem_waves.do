set top "tb_memorysystem"
set mem_unit "$top/DUT_MemorySystem"
set mem_unit_top true

delete wave *
add wave $top/clk
add wave $top/rst_n

set dcache $mem_unit/DCache
set icache $mem_unit/ICache
set arbiter $mem_unit/Arbiter
set interface $mem_unit/WBInterface

add wave -divider "Instruction Cache"

add wave -hex $icache/i_request_addr
add wave $icache/o_hit

add wave $icache/i_rd_request
add wave -hex $icache/o_data_out

add wave $icache/state
add wave $icache/state_next

add wave -divider "Data Cache"

add wave -hex $dcache/i_request_addr
add wave $dcache/o_hit

add wave $dcache/i_rd_request
add wave -hex $dcache/o_data_out

add wave $dcache/i_wr_request
add wave -hex $dcache/i_wr_data

add wave -hex $dcache/sets
add wave -hex $dcache/mru_bits_next
add wave -hex $dcache/input_tag
add wave -hex $dcache/input_set
add wave $dcache/state

add wave -divider "Arbiter"

add wave $arbiter/state

add wave -hex $arbiter/*_icache_*
add wave -hex $arbiter/*_dcache_*

add wave -divider "Wishbone Interface"
add wave -hex $interface/state
add wave -hex $interface/*_mem_*


if {$mem_unit_top} {
    add wave -divider "Wishbone Line"

    add wave -hex $top/wb_*

    add wave -divider "Wishbone Memory"

    add wave -hex $top/DUT_Memory/memory
    add wave -hex $top/mirror_memory
}
