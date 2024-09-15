# Change this path to the path of the tech library
set search_path { . /path/to/library }
set link_library  {NangateOpenCellLibrary_typical_ecsm.db}
set target_library  {NangateOpenCellLibrary_typical_ecsm.db}

define_design_lib -path ./work WORK

set hdlin_enable_configurations "true"
set power_preserve_rtl_hier_names "true"

set block_name "DLX"

set sdc_file "sdc/DLX.sdc"

set outdir "./saved"
file mkdir $outdir

set outdir "$outdir/$block_name"
file mkdir $outdir

set sources_filename "../sim/sources.f"
set fp [open $sources_filename r]
set sources [split [read $fp] "\n"]
close $fp

analyze -format vhdl -library work $sources

elaborate -lib work $block_name -parameters BTB_LINES_WIDTH=>3,DATA_CACHE_LINE_SIZE=>8,DATA_CACHE_NSETS=>4,DATA_CACHE_WAYS=>6
set_wire_load_model -name 5K_hvratio_1_4

source $sdc_file

puts "## COMPILE ## " 

;# Enable Clock Gating
set_clock_gating_style \
    -minimum_bitwidth 4 \
    -max_fanout 1024

compile_ultra -gate_clock

puts "## SECOND COMPILE ##"

compile -map_effort high -incremental_mapping


puts "## ALL DONE! WRITING REPORTS ##"
report_clock_gating > "$outdir/clock_gating.rpt"
report_clock_gating -structure > "$outdir/clock_gating_structure.rpt"
report_clock_gating -enable_conditions > "$outdir/clock_gating_enable_conditions.rpt"

report_timing > "$outdir/timing.rpt"
report_power  > "$outdir/power.rpt"
report_area   > "$outdir/area.rpt"

write -hierarchy -f verilog -output "$outdir/${block_name}_postsyn.v"
write_sdc "$outdir/${block_name}.sdc"
write_sdc -version 1.3 "$outdir/${block_name}_1.3.sdc"

puts "## WRITING SDF REPORT (This may take a while) ##"
write_sdf "$outdir/${block_name}.sdf"
