set clock_name "CLK"

set clock_period 1.6

create_clock -name $clock_name -period $clock_period i_wb_clk
report_clock > "$outdir/clocks.rpt"

set_max_delay -from [all_inputs] -to [all_outputs] $clock_period
