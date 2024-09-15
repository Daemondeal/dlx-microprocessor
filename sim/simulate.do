quietly set TOP_ENTITY_DEFAULT tb_BTB

quietly set TESTBENCHES {
    tb_AdderSubtractor
    tb_Shifter
    tb_UpCounter
    tb_MemorySystem
    tb_ReadOnlyCache
    tb_WriteThroughCache
    tb_Alu
    tb_Divider
    tb_BTB
    tb_LoadStoreUnit
    tb_RegisterFile
    tb_Boothmul
}

proc compile_all { {enable_coverage false} } {
    if {$enable_coverage} {
        vcom -source -coveropt 3 +cover -coverexcludedefault -F ./sources.f
    } else {
        vcom -source -F ./sources.f 
    }

    vcom -source -F ./sources_tb.f 
}

# Simulates a design and returns { total_assertions misses }
proc simulate_and_get_stats { top_entity { enable_coverage false } } {
    if { $enable_coverage } {
        vsim work.$top_entity -t 10ps -quiet -coverage
    } else {
        vsim work.$top_entity -t 10ps -quiet
    }
    run -all

    set report [coverage report -assertion -summary]
    if { $report != "" } {
        set match [
            regexp {Assertions\s*(\d+)\s*(\d+)\s*(\d+)} $report match bins hits misses
        ]

        if { $match } {
            return [list $bins $misses]
        }
    }

    return { 0 0 }
}

proc simulate_all { { arg "" } } {
    set enable_coverage [expr {$arg == "-coverage"}]
    compile_all $enable_coverage

    set total_assertions 0
    set failing_assertions 0

    set failing_testbenches [list]
    set fail_number [list]
    set fail_reports [list]

    if { $enable_coverage } {
        set coverage_files [list]
        file mkdir ./build/
        file mkdir ./build/coverage
        coverage save -onexit -directive -codeAll -cvg coverage.ucdb
    }

    foreach tb $::TESTBENCHES {
        lassign [simulate_and_get_stats $tb $enable_coverage] total misses

        if { $enable_coverage } {
            set coverfile "./build/coverage/${tb}.ucdb"
            coverage save -directive -codeAll -cvg $coverfile
            lappend coverage_files $coverfile
        }

        if { $misses > 0 } {
            puts "\[$tb\] Test failed"

            lappend failing_testbenches $tb
            lappend fail_number $misses
            lappend fail_reports [coverage report -assertion -details]
        } else {
            puts "\[$tb\] Test succeded!"
        }

        set total_assertions [expr {$total_assertions + $total}]
        set failing_assertions [expr {$failing_assertions + $misses}]
    }

    set passing_assertions [expr {$total_assertions - $failing_assertions}]
    set percentage [format "%.2f" [expr {double($passing_assertions)/double($total_assertions) * 100.0}]]
    puts ""
    puts ""
    puts "### TEST DONE ###"
    puts "Passing Assertions: $passing_assertions/$total_assertions ($percentage %)"

    set ansi_red "\033\[31m"
    set ansi_green "\033\[32m"
    set ansi_reset "\033\[0m"
    if {$failing_assertions > 0} {

        puts "${ansi_red} Tests Failed ${ansi_reset}"
        puts "Failing testbenches: "
        set zipped_tb [lmap l1 $failing_testbenches l2 $fail_number {list $l1 $l2}] 

        foreach failing_tb $zipped_tb {
            lassign $failing_tb name failures

            puts "- $name ($failures failures)"
        }
    } else {
        puts "${ansi_green}All tests passed!${ansi_reset}"
    }
    puts ""

    if { $enable_coverage } {
        set final_coverfile "./build/coverage/full_coverage.ucdb"
        vcover merge $final_coverfile {*}$coverage_files
        vcover report -details -html $final_coverfile -output ./build/coverage/html/
    }
}

proc show_failures {} {
    show_prettified_report [coverage report -assertion -details]
}

proc show_prettified_report { report } {
    set report [regsub {ASSERTION RESULTS.*} $report ""]
    set tuples [regexp -all -inline {([.a-zA-Z0-9\\/_\-]+)\((\d+)\)\n\s*(\d+)\s*(\d+)} $report] 
    foreach {_match file line_number failures passes} $tuples {
        if { $failures > 0 } {
            echo "- line $line_number: $failures fails"
        }
    }
}

proc resim { {time 0} } {
    compile_all

    restart -f

    if {$time == 0} {
        run -all
    } else {
        run $time ns
    }
}

proc start_sim { args } {
    array set params [list  \
        -top $::TOP_ENTITY_DEFAULT  \
        -generics ""   \
        -wavefile  "waves.wlf"  \
        -wave_setup ""  \
        -precision "10ps"  \
        -time ""  \
        -compile true  \
    ]


    if {[llength $args] == 1} {
        array set params [list "-top" $args]
    } else {
        array set params $args
    }

    if { $params(-compile) } {
        compile_all false
    }

    regexp {vsim\s(\d+)} [vsim -version] match year
    set match_questa [regexp {[qQ]uesta} [vsim -version]]
    set is_new_version [expr {$year > 2020 || $match_questa }]

    if {$is_new_version} {
        set SIM_FLAGS {-vopt -voptargs=+acc}
    } else {
        set SIM_FLAGS ""
    }

    set generics [split $params(-generics) ","]
    set sim_generics [list]
    foreach generic $generics {
        lappend sim_generics "-g$generic"
    }


    vsim work.$params(-top) \
        -wave $params(-wavefile) \
        -t $params(-precision) \
        -quiet \
        {*}$SIM_FLAGS \
        {*}$sim_generics

    if {$params(-wave_setup) == ""} {
        add wave -hex *
    } else {
        source $params(-wave_setup)
    }

    if {$params(-time) == ""} {
        run -all
    } else {
        run $params(-time)
    }
}
