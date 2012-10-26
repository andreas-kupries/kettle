# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle a tclbench-based benchmarks

# Loaded after testsuite,tcl, we can assume the presence of the
# options --with-shell, --log, and --log-mode.

namespace eval ::kettle { namespace export benchmarks }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::benchmarks {{benchsrcdir bench}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::benchmarks args {}

    # Heuristic search for benchmarks
    # Aborts caller when nothing is found.
   lassign [path scan \
		{tclbench benchmarks} \
		$benchsrcdir \
		{path bench-file}] \
	root benchmarks

    # Put the benchmarks into recipes.

    recipe define bench {
	Run the benchmarks
    } {benchsrcdir benchmarks} {
	# Note: We build and install the package under profiling (and
	# its dependencies) into a local directory (in the current
	# working directory). We try to install a debug variant first,
	# and if that fails a regular one.

	set tmp [path norm [path tmpfile bench_install_]]
	try {
	    if {![invoke self debug   --prefix $tmp] &&
		![invoke self install --prefix $tmp]
	    } {
		status fail "Unable to generate local benchmark installation"
	    }

	    Bench::Run $benchsrcdir $benchmarks $tmp
	} finally {
	    file delete -force $tmp
	}
    } $root $benchmarks

    return
}

# # ## ### ##### ######## ############# #####################
## Support code for the recipe.

namespace eval ::kettle::Bench {
    namespace import ::kettle::path
    namespace import ::kettle::io
    namespace import ::kettle::status
    namespace import ::kettle::option
    namespace import ::kettle::strutil
    namespace import ::kettle::stream
}

proc ::kettle::Bench::Run {srcdir benchfiles localprefix} {
    # We are running each bench file in a separate sub process, to
    # catch crashes, etc. ... We assume that the bench file is self
    # contained in terms of loading all its dependencies, like
    # tclbench itself, utility commands it may need, etc. This
    # assumption allows us to run it directly, using our own
    # tcl executable as interpreter.

    stream to log ============================================================

    set main [path norm [option get @kettledir]/benchmain.tcl]
    InitState

    path in $srcdir {
	foreach bench $benchfiles {
	    # change next to log/log
	    #io note { io puts ${bench}... }
	    stream aopen

	    path pipe line {
		io trace {BENCH: $line}
		ProcessLine $line
	    } [option get --with-shell] $main $localprefix $bench

	    io for-terminal {
		io puts "\r                                               "
	    }
	}
    }

    # Summary results...
    stream to summary  {[FormatTimings $state]}
    stream term always  [FormatResults $state]

    # Report ok/fail
    status [dict get $state status]
    return
}

proc ::kettle::Bench::FormatTimings {state} {
    # Extract data ...
    set times [dict get $state times]

    # Sort by shell and benchmark, re-package into tuples.
    set tmp {}
    foreach k [lsort -dict [dict keys $times]] {
	lassign $k                   shell suite
	lassign [dict get $times $k] nbench sec usec
	lappend tmp [list $shell $suite $nbench $sec $usec]
    }

    # Sort tuples by time per benchmark, and transpose into
    # columns. Add the header and footer lines.

    lappend sh Shell      =====
    lappend ts Benchsuite ==========
    lappend nb Benchmarks ==========
    lappend ns Seconds    =======
    lappend us uSec/Bench ==========

    foreach item [lsort -index 4 -decreasing $tmp] {
	lassign $item shell suite nbench sec usec
	lappend sh $shell
	lappend ts $suite
	lappend nb $nbench
	lappend ns $sec
	lappend us $usec
    }

    lappend sh =====
    lappend ts ==========
    lappend nb ==========
    lappend ns =======
    lappend us ==========

    # Print the columns, each padded for vertical alignment.

    lappend lines \nTimings...
    foreach \
	shell  [strutil padr $sh] \
	suite  [strutil padr $ts] \
	nbench [strutil padr $nb] \
	sec    [strutil padr $ns] \
	usec   [strutil padr $us] {
	    lappend lines "$shell $suite $nbench $sec $usec"
	}

    return [join $lines \n]
}

proc ::kettle::Bench::FormatResults {state} {
    # Extract data ...
    set results [dict get $state results]

    # row = shell ver benchfile description time

    # Sort by description.
    set tmp {}
    foreach k [lsort -index 3 -dict $results] {
	lassign $k _ _ _ d t
	lappend tmp [list $d $t]
    }

    # Transpose into columns. Add the header and footer lines.
    lappend ds Description ===========
    lappend ts Time        ====

    foreach item $tmp {
	lassign $item d t
	lappend ds $d
	lappend ts $t
    }

    lappend ds =========== Description
    lappend ts ====	   Time

    # Print the columns, each padded for vertical alignment.

    lappend lines \nResults...
    foreach \
	d  [strutil padr $ds] \
	t  [strutil padr $ts] {
	    lappend lines "$d $t"
	}

    return \t[join $lines \n\t]
}

proc ::kettle::Bench::ProcessLine {line} {
    # Counters and other state in the calling environment.
    upvar 1 state state

    set line [string trimright $line]

    if {![string match {TRACK *} $line]} {
	stream term full $line
	stream to log   {$line}
    }

    set rline $line
    set line [string trim $line]
    if {[string equal $line ""]} return

    # Recognize various parts written by the sub-shell and act on
    # them. If a line is recognized and acted upon the remaining
    # matchers are _not_ executed.

    Host;Platform;Cwd;Shell;Tcl
    Start;End;Benchmark
    Support;Benching

    CaptureStackStart
    CaptureStack

    BenchLog;BenchStart;BenchTrack;BenchResult

    Aborted
    AbortCause

    Misc

    # Unknown lines are printed
    stream term compact !$line
    return
}

# # ## ### ##### ######## ############# #####################

proc ::kettle::Bench::InitState {} {
    upvar 1 state state
    # The counters are all updated in ProcessLine.
    # The status may change to 'fail' in ProcessLine.
    set state {
	cerrors  0
	status   ok

	host     {}
	platform {}
	cwd      {}
	shell    {}
	file     {}
	bench    {}
	start    {}
	times    {}
	results  {}

	suite/status ok

	cap/state none
	cap/stack off
    }
    return
}

proc ::kettle::Bench::Host {} {
    upvar 1 line line state state
    if {![regexp "^@@ Host (.*)$" $line -> host]} return
    #stream aextend $host
    #stream term compact "Host     $host"
    dict set state host $host
    # FUTURE: Write bench results to a storage back end for analysis.
    return -code return
}

proc ::kettle::Bench::Platform {} {
    upvar 1 line line state state
    if {![regexp "^@@ Platform (.*)$" $line -> platform]} return
    #stream term compact "Platform $platform"
    dict set state platform $platform
    #stream aextend ($platform)
    return -code return
}

proc ::kettle::Bench::Cwd {} {
    upvar 1 line line state state
    if {![regexp "^@@ BenchCWD (.*)$" $line -> cwd]} return
    #stream term compact "Cwd      [path relativecwd $cwd]"
    dict set state cwd $cwd
    return -code return
}

proc ::kettle::Bench::Shell {} {
    upvar 1 line line state state
    if {![regexp "^@@ Shell (.*)$" $line -> shell]} return
    #stream term compact "Shell    $shell"
    dict set state shell $shell
    #stream aextend [file tail $shell]
    return -code return
}

proc ::kettle::Bench::Tcl {} {
    upvar 1 line line state state
    if {![regexp "^@@ Tcl (.*)$" $line -> tcl]} return
    #stream term compact "Tcl      $tcl"
    dict set state tcl $tcl
    stream aextend "\[$tcl\] "
    return -code return
}

proc ::kettle::Bench::Misc {} {
    upvar 1 line line state state
    if {[string match "@@ BenchDir*" $line]} {return -code return}
    if {[string match "@@ LocalDir*" $line]} {return -code return}
    return
}

proc ::kettle::Bench::Start {} {
    upvar 1 line line state state
    if {![regexp "^@@ Start (.*)$" $line -> start]} return
    #stream term compact "Start    [clock format $start]"
    dict set state start $start
    dict set state benchnum 0
    return -code return
}

proc ::kettle::Bench::End {} {
    upvar 1 line line state state
    if {![regexp "^@@ End (.*)$" $line -> end]} return

    set start [dict get $state start]
    set shell [dict get $state shell]
    set file  [dict get $state file]
    set num   [dict get $state benchnum]
    set err   [dict get $state cerrors]

    stream awrite "~~    $num"
    if {$err} {
	stream aclose "~~ [io mred ERR] $num"
    } else {
	stream aclose "~~ OK  $num"
    }

    #stream term compact "Started  [clock format $start]"
    #stream term compact "End      [clock format $end]"

    set delta [expr {$end - $start}]
    if {$num == 0} {
	set score $delta
    } else {
	# Get average number of microseconds per test.
	set score [expr {int(($delta/double($num))*1000000)}]
    }

    set key [list $shell $file]

    dict lappend state times $key [list $num $delta $score]

    stream to timings {[list TIME $key $num $delta $score]}
    return -code return
}

proc ::kettle::Bench::Benchmark {} {
    upvar 1 line line state state ; variable xfile
    if {![regexp "^@@ Benchmark (.*)$" $line -> file]} return
    #stream term compact "Benchmark $file"
    dict set state file $file
    stream aextend "[file tail $file] "
    return -code return
}

proc ::kettle::Bench::Support {} {
    upvar 1 line line state state
    #stream awrite "S $package" /when caught
    #if {[regexp "^SYSTEM - (.*)$" $line -> package]} {stream term compact "Ss $package";return -code return}
    #if {[regexp "^LOCAL  - (.*)$" $line -> package]} {stream term compact "Sl $package";return -code return}
    if {[regexp "^SYSTEM - (.*)$" $line -> package]} {return -code return}
    if {[regexp "^LOCAL  - (.*)$" $line -> package]} {return -code return}
    return

}

proc ::kettle::Bench::Benching {} {
    upvar 1 line line state state
    #stream awrite "T $package" /when caught
    #if {[regexp "^SYSTEM % (.*)$" $line -> package]} {stream term compact "Ts $package";return -code return}
    #if {[regexp "^LOCAL  % (.*)$" $line -> package]} {stream term compact "Tl $package";return -code return}
    if {[regexp "^SYSTEM % (.*)$" $line -> package]} {return -code return}
    if {[regexp "^LOCAL  % (.*)$" $line -> package]} {return -code return}
    return
}

proc ::kettle::Bench::BenchLog {} {
    upvar 1 line line state state
    if {![string match {LOG *} $line]} return
    # Ignore unstructured feedback.
    return -code return
}

proc ::kettle::Bench::BenchStart {} {
    upvar 1 line line state state
    if {![string match {START *} $line]} return
    lassign $line _ description iter
    dict set state bench $description
    dict incr state benchnum
    set w [string length $iter]
    dict set state witer $w
    dict set state iter  $iter
    stream awrite "\[[format %${w}s {}]\] $description"
    return -code return
}

proc ::kettle::Bench::BenchTrack {} {
    upvar 1 line line state state
    if {![string match {TRACK *} $line]} return
    lassign $line _ description at
    set w [dict get $state witer]
    stream awrite "\[[format %${w}s $at]\] $description"
    return -code return
}

proc ::kettle::Bench::BenchResult {} {
    upvar 1 line line state state
    if {![string match {RESULT *} $line]} return
    lassign $line _ description time
    #stream awrite "$description = $time"

    set sh   [dict get $state shell]
    set ver  [dict get $state tcl]
    set file [dict get $state file]

    set row [list $sh $ver $file $description $time]

    dict lappend state results $row
    stream to results  {"[join $row {","}]"}

    dict set state bench {}
    dict set state witer {}
    return -code return
}

proc ::kettle::Bench::CaptureStackStart {} {
    upvar 1 line line state state
    if {![string match {@+*} $line]} return

    dict set state cap/stack    on
    dict set state stack        {}
    dict set state suite/status error
    dict incr state cerrors

    stream aextend "[io mred {Caught Error}] "
    return -code return
}

proc ::kettle::Bench::CaptureStack {} {
    upvar 1 state state
    if {![dict get $state cap/stack]} return
    upvar 1 line line

    if {![string match {@-*} $line]} {
	dict append state stack [string range $line 2 end] \n
	return -code return
    }

    if {[stream active]} {
	stream aextend ([io mblue {Stacktrace saved}])

	set file  [lindex [dict get $state file] end]
	set stack [dict get $state stack]

	stream to stacktrace {$file StackTrace}
	stream to stacktrace ========================================
	stream to stacktrace {$stack}
	stream to stacktrace ========================================\n\n
    } else {
	stream aextend "([io mred {Stacktrace not saved}]. [io mblue {Use --log}])"
    }

    dict set   state cap/stack off
    dict unset state stack

    stream aclose ""
    return -code return
}

proc ::kettle::Bench::Aborted {} {
    upvar 1 line line state state
    if {![string match {Aborting the benchmarks found *} $line]} return
    # Ignore aborted status if we already have it, or some other error
    # status (like error, or fail). These are more important to show.
    if {[dict get $state suite/status] eq "ok"} {
	dict set state suite/status aborted
    }
    stream aextend "[io mred Aborted:] "
    return -code return
}

proc ::kettle::Bench::AbortCause {} {
    upvar 1 line line state state
    if {
	![string match {Requir*}    $line] &&
	![string match {Error in *} $line]
    } return ; # {}

    stream aclose $line
    return -code return
}

# # ## ### ##### ######## ############# #####################
return
