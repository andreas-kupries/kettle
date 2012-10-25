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

    recipe define test {
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

    # Dictionary of log streams. Maps names to write command.
    variable stream {}
    # Names of our streams.
    variable streams {
	log summary aborted
	stacktrace timings
    }
}

proc ::kettle::Bench::Run {srcdir benchfiles localprefix} {
    # We are running each bench file in a separate sub process, to
    # catch crashes, etc. ... We assume that the bench file is self
    # contained in terms of loading all its dependencies, like
    # tclbench itself, utility commands it may need, etc. This
    # assumption allows us to run it directly, using our own
    # tcl executable as interpreter.

    StreamsBegin
    Stream log ============================================================

    set main [path norm [option get @kettledir]/benchmain.tcl]
    InitState

    path in $srcdir {
	foreach bench $benchfiles {
	    # change next to log/log
	    #io note { io puts ${bench}... }
	    Aopen

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
    # ... the numbers
    set fn [dict get $state cfailed]
    set en [dict get $state cerrors]
    set tn [dict get $state ctotal]
    set pn [dict get $state cpassed]
    set sn [dict get $state cskipped]

    # ... formatted
    set t $tn;#[format %6d $tn]
    set p [format %6d $pn]
    set s [format %6d $sn]
    set f [format %6d $fn]
    set e [format %6d $en]

    # ... and colorized where needed.
    if {$pn} { set p [io mgreen   $p] }
    if {$sn} { set s [io mblue    $s] }
    if {$fn} { set f [io mred     $f] }
    if {$en} { set e [io mmagenta $e] }

    # Show in terminal, always...
    Log* "Passed  $p of $t"
    Log* "Skipped $s of $t"
    Log* "Failed  $f of $t"
    Log* "#Errors $e"

    # And in the main stream...
    Stream log "Passed  $p of $t"
    Stream log "Skipped $s of $t"
    Stream log "Failed  $f of $t"
    Stream log "#Errors $e"

    if {[Streams]} {
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

	lappend sh Shell     =====
	lappend ts Benchsuite =========
	lappend nt Benchs     =====
	lappend ns Seconds   =======
	lappend us uSec/Bench =========

	foreach item [lsort -index 4 -decreasing $tmp] {
	    lassign $item shell suite nbench sec usec
	    lappend sh $shell
	    lappend ts $suite
	    lappend nt $nbench
	    lappend ns $sec
	    lappend us $usec
	}

	lappend sh =====
	lappend ts =========
	lappend nt =====
	lappend ns =======
	lappend us =========

	# Print the columns, each padded for vertical alignment.

	Stream summary \nTimings...
	foreach \
	    shell  [strutil padr $sh] \
	    suite  [strutil padr $ts] \
	    nbench [strutil padr $nt] \
	    sec    [strutil padr $ns] \
	    usec   [strutil padr $us] {
	    Stream summary "$shell $suite $nbench $sec $usec"
	}
    }

    StreamsDone

    # Report ok/fail
    status [dict get $state status]
    return
}

proc ::kettle::Bench::ProcessLine {line} {
    # Counters and other state in the calling environment.
    upvar 1 state state

    set line [string trimright $line]

    LogF       $line
    Stream log $line

    set rline $line
    set line [string trim $line]
    if {[string equal $line ""]} return

    # Recognize various parts written by the sub-shell and act on
    # them. If a line is recognized and acted upon the remaining
    # matchers are _not_ executed.

    Host;Platform;Cwd;Shell;Tcl
    Start;End
    Support;Benching
    Summary

    CaptureStackStart
    CaptureStack

    # BenchResult

    Aborted
    AbortCause

    Match||Skip||Sourced

    # Unknown lines are printed
    LogC !$line
    return
}

# # ## ### ##### ######## ############# #####################
## Terminal log.
##
## F Write on full.
## C Write on compact
## * Write always
##

proc ::kettle::Bench::LogF {text} {
    if {[option get --log-mode] ne "full"} return
    io puts $text
    return
}

proc ::kettle::Bench::LogC {text} {
    if {[option get --log-mode] ne "compact"} return
    io puts $text
    return
}

proc ::kettle::Bench::Log* {text} {
    io puts $text
    return
}

proc ::kettle::Bench::Aopen {} {
    if {[option get --log-mode] ne "compact"} return
    io animation begin
    return
}

proc ::kettle::Bench::Aclose {text} {
    upvar 1 state state

    if {[option get --log-mode] eq "compact"} {
	io animation last $text
    }

    if {![Streams]} return

    set file [file tail [dict get $state file]]
    set text "\[$file\] $text"

    Stream summary $text
    # Maybe use a mapping table here instead, status to stream.
    switch -exact -- [dict get $state suite/status] {
	error   -
	fail    { Stream failures $text }
	none    { Stream none     $text }
	aborted { Stream aborted  $text }
    }
    return
}

proc ::kettle::Bench::Aextend {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation indent $text
    io animation write  ""
    return
    
}

proc ::kettle::Bench::Awrite {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation write $text
    return
}

# # ## ### ##### ######## ############# #####################
# Log streams ....

proc ::kettle::Bench::Streams {} {
    expr {[option get --log] ne {}}
}

proc ::kettle::Bench::Stream {name text} {
    variable stream
    {*}[dict get $stream $name] $text
    return
}

proc ::kettle::Bench::StreamsBegin {} {
    variable stream
    variable streams

    if {[option get --log] ne {}} {
	# Log file (stem) specified, generate all log streams.
	# Creation is defered until actual use.
	set stem [option get --log]
	foreach name $streams {
	    dict set stream $name \
		[list ::kettle::Bench::StreamsMake $stem $name]
	}
    } else {
	# Without stem we generate no streams.
	dict set stream log ::kettle::io::puts
	foreach name $streams {
	    dict set stream $name ::kettle::Bench::StreamsNull
	}
    }
}

proc ::kettle::Bench::StreamsDone {} {
    variable stream
    dict for {name cmd} $stream {
	if {[lindex $cmd 0] ne "::puts"} continue
	close [lindex $cmd 1]
    }
    return
}

# Writer for log streams. Create on demand, on first write.
proc ::kettle::Bench::StreamsMake {stem name text} {
    variable stream
    file mkdir [file dirname $stem.$name]
    dict set stream $name [list ::puts [open $stem.$name w]]
    Stream $name $text
    return
}

# Writer for disabled streams, doing nothing.
proc ::kettle::Bench::StreamsNull {args} {}

# # ## ### ##### ######## ############# #####################

proc ::kettle::Bench::InitState {} {
    upvar 1 state state
    # The counters are all updated in ProcessLine.
    # The status may change to 'fail' in ProcessLine.
    set state {
	ctotal   0
	status   ok

	host     {}
	platform {}
	cwd      {}
	shell    {}
	file     {}
	test     {}
	start    {}
	times    {}

	suite/status ok

	cap/state none
	cap/stack off
    }
    return
}

proc ::kettle::Bench::Host {} {
    upvar 1 line line state state
    if {![regexp "^@@ Host (.*)$" $line -> host]} return
    #Aextend $host
    #LogC "Host     $host"
    dict set state host $host
    # FUTURE: Write bench results to a storage back end for analysis.
    return -code return
}

proc ::kettle::Bench::Platform {} {
    upvar 1 line line state state
    if {![regexp "^@@ Platform (.*)$" $line -> platform]} return
    #LogC "Platform $platform"
    dict set state platform $platform
    #Aextend ($platform)
    return -code return
}

proc ::kettle::Bench::Cwd {} {
    upvar 1 line line state state
    if {![regexp "^@@ BenchCWD (.*)$" $line -> cwd]} return
    #LogC "Cwd      [path relativecwd $cwd]"
    dict set state cwd $cwd
    return -code return
}

proc ::kettle::Bench::Shell {} {
    upvar 1 line line state state
    if {![regexp "^@@ Shell (.*)$" $line -> shell]} return
    #LogC "Shell    $shell"
    dict set state shell $shell
    #Aextend [file tail $shell]
    return -code return
}

proc ::kettle::Bench::Tcl {} {
    upvar 1 line line state state
    if {![regexp "^@@ Tcl (.*)$" $line -> tcl]} return
    #LogC "Tcl      $tcl"
    dict set state tcl $tcl
    Aextend "\[$tcl\] "
    return -code return
}

proc ::kettle::Bench::Match||Skip||Sourced {} {
    upvar 1 line line state state
    if {[string match "@@ BenchDir*" $line]} {return -code return}
    if {[string match "@@ LocalDir*" $line]} {return -code return}
    return
}

proc ::kettle::Bench::Start {} {
    upvar 1 line line state state
    if {![regexp "^@@ Start (.*)$" $line -> start]} return
    #LogC "Start    [clock format $start]"
    dict set state start $start
    dict set state testnum 0
    return -code return
}

proc ::kettle::Bench::End {} {
    upvar 1 line line state state
    if {![regexp "^@@ End (.*)$" $line -> end]} return

    set start [dict get $state start]
    set shell [dict get $state shell]
    set file  [dict get $state file]
    set num   [dict get $state testnum]

    #LogC "Started  [clock format $start]"
    #LogC "End      [clock format $end]"

    set delta [expr {$end - $start}]
    if {$num == 0} {
	set score $delta
    } else {
	# Get average number of microseconds per test.
	set score [expr {int(($delta/double($num))*1000000)}]
    }

    set key [list $shell $file]

    dict lappend state times $key [list $num $delta $score]

    Stream timings [list TIME $key $num $delta $score]
    #variable xshell
    #sak::registry::local set $xshell End $end
    return -code return
}

proc ::kettle::Bench::Support {} {
    upvar 1 line line state state
    #Awrite "S $package" /when caught
    #if {[regexp "^SYSTEM - (.*)$" $line -> package]} {LogC "Ss $package";return -code return}
    #if {[regexp "^LOCAL  - (.*)$" $line -> package]} {LogC "Sl $package";return -code return}
    if {[regexp "^SYSTEM - (.*)$" $line -> package]} {return -code return}
    if {[regexp "^LOCAL  - (.*)$" $line -> package]} {return -code return}
    return

}

proc ::kettle::Bench::Benching {} {
    upvar 1 line line state state
    #Awrite "T $package" /when caught
    #if {[regexp "^SYSTEM % (.*)$" $line -> package]} {LogC "Ts $package";return -code return}
    #if {[regexp "^LOCAL  % (.*)$" $line -> package]} {LogC "Tl $package";return -code return}
    if {[regexp "^SYSTEM % (.*)$" $line -> package]} {return -code return}
    if {[regexp "^LOCAL  % (.*)$" $line -> package]} {return -code return}
    return
}

proc ::kettle::Bench::Summary {} {
    upvar 1 line line state state
    variable statelabel
    #LogC S?$line
    if {![regexp "(Total(.*)Passed(.*)Skipped(.*)Failed(.*))$" $line -> line]} return

    lassign [string trim $line] _ total _ passed _ skipped _ failed

    dict incr state ctotal   $total
    dict incr state cpassed  $passed
    dict incr state cskipped $skipped
    dict incr state cfailed  $failed

    set total   [format %5d $total]
    set passed  [format %5d $passed]
    set skipped [format %5d $skipped]
    set failed  [format %5d $failed]

    set thestate [dict get $state suite/status]

    if {!$total && ($thestate eq "ok")} {
	dict set state suite/status none
	set thestate         none
    }

    set st [dict get $statelabel $thestate]

    if {$thestate eq "ok"} {
	# Quick return for ok suite.
	Aclose "~~ $st T $total P $passed S $skipped F $failed"
	return -code return
    }

    # Clean out progress display using a non-highlighted string.
    # Prevents the char count from being off. This is followed by
    # construction and display of the highlighted version.

    Awrite "   $st T $total P $passed S $skipped F $failed"
    switch -exact -- $thestate {
	none    { Aclose "~~ [io myellow "$st T $total"] P $passed S $skipped F $failed" }
	aborted { Aclose "~~ [io mwhite   $st] T $total P $passed S $skipped F $failed" }
	error   { Aclose "~~ [io mmagenta $st] T $total P $passed S $skipped F $failed" }
	fail    { Aclose "~~ [io mred     $st] T $total P $passed S $skipped [io mred "F $failed"]" }
    }

    if {$thestate eq "error"} { dict incr state cerrors }
    return -code return
}

proc ::kettle::Bench::CaptureStackStart {} {
    upvar 1 line line state state
    if {![string match {@+*} $line]} return

    dict set state cap/stack    on
    dict set state stack        {}
    dict set state suite/status error
    dict incr state cerrors

    Aextend "[io mred {Caught Error}] "
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

    if {[Streams]} {
	Aextend ([io mblue {Stacktrace saved}])

	set file  [dict get $state file]
	set stack [dict get $state stack]

	Stream stacktrace "[lindex $file end] StackTrace"
	Stream stacktrace "========================================"
	Stream stacktrace $stack
	Stream stacktrace "========================================\n\n"
    } else {
	Aextend "([io mred {Stacktrace not saved}]. [io mblue {Use --log}])"
    }

    dict set   state cap/stack off
    dict unset state stack

    Aclose ""
    return -code return
}

proc ::kettle::Bench::Aborted {} {
    upvar 1 line line state state
    if {![string match {Aborting the tests found *} $line]} return
    # Ignore aborted status if we already have it, or some other error
    # status (like error, or fail). These are more important to show.
    if {[dict get $state suite/status] eq "ok"} {
	dict set state suite/status aborted
    }
    Aextend "[io mred Aborted:] "
    return -code return
}

proc ::kettle::Bench::AbortCause {} {
    upvar 1 line line state state
    if {
	![string match {Requir*}    $line] &&
	![string match {Error in *} $line]
    } return ; # {}

    Aclose $line
    return -code return
}

# # ## ### ##### ######## ############# #####################
return
