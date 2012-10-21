# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle a tcltest-based testsuite

namespace eval ::kettle { namespace export testsuite }

# # ## ### ##### ######## ############# #####################
## Shell to run the tests with.
## Irrelevant to work database keying.

kettle option define --with-shell {
    'test' option. Path of the shell to run the tests with.
    Defaults to the tclsh running the kettle build code.
} [kettle path norm [info nameofexecutable]]

kettle option no-work-key --with-shell
kettle option onchange    --with-shell {} {
    set! --with-shell [path norm $new]
}

# # ## ### ##### ######## ############# #####################
## Mode and file/channel for logging of test output.
## Irrelevant to work database keying.

# We have two different log systems here, actually.
#
# 1. Logging to the terminal (= stdout).
#    This can be done in compact and full modes.
#    The option to set this is --log-mode.
#
# 2. Logging to a set of files, for multiple log 'streams'.
#    The option --log specifies their (path) stem.
#    If no stem is specified no streams are generated.

kettle option define --log-mode {
    'test' option. Verbosity of the logging on the terminal.
} compact {enum {compact full}}
kettle option no-work-key --log-mode

kettle option define --log {
    'test' option. Path (stem) for a set of files to log to
    (independent of logging to the terminal).
} {} path
kettle option onchange    --log {} { set! --log [path norm $new] }
kettle option no-work-key --log

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::testsuite {{testsrcdir tests}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::testsuite args {}

    # Heuristic search for testsuite
    # Aborts caller when nothing is found.
   lassign [path scan \
		{tcltest testsuite} \
		$testsrcdir \
		{path tcltest-file}] \
	root testsuite

    # Put the testsuite into recipes.

    recipe define test {
	Run the testsuite
    } {testsrcdir testsuite} {
	# Note: We build and install the package under test (and its
	# dependencies) into a local directory (in the current working
	# directory). We try to install a debug variant first, and if
	# that fails a regular one. This is important for

	set tmp [path norm [path tmpfile test_install_]]
	try {
	    if {![invoke self debug   --prefix $tmp] &&
		![invoke self install --prefix $tmp]
	    } {
		status fail "Unable to generate local test installation"
	    }

	    Test::Run $testsrcdir $testsuite $tmp
	} finally {
	    file delete -force $tmp
	}
    } $root $testsuite

    return
}

# # ## ### ##### ######## ############# #####################
## Support code for the recipe.

namespace eval ::kettle::Test {
    namespace import ::kettle::path
    namespace import ::kettle::io
    namespace import ::kettle::status
    namespace import ::kettle::option
    namespace import ::kettle::strutil

    # Dictionary of log streams. Maps names to write command.
    variable stream {}
    # Names of our streams.
    variable streams {
	log summary failures aborted none
	stacktrace faildetails timings
    }

    # Map from testsuite states to readable labels. These include
    # trailing whitespace to align the following text vertically.
    variable statelabel {
	ok      {     }
	none    {None }
	aborted {Skip }
	error   {ERR  }
	fail    {FAILS}
    }
}

proc ::kettle::Test::Run {srcdir testfiles localprefix} {
    # We are running each test file in a separate sub process, to
    # catch crashes, etc. ... We assume that the test file is self
    # contained in terms of loading all its dependencies, like
    # tcltest itself, utility commands it may need, etc. This
    # assumption allows us to run it directly, using our own
    # tcl executable as interpreter.

    # options for tcltest. (l => line information for failed tests).

    # Note: See tcllib's sak.tcl for a more mature and featureful
    # system of running a testsuite and postprocessing results.

    StreamsBegin
    Stream log ============================================================

    set main [path norm [option get @kettledir]/testmain.tcl]
    InitState

    path in $srcdir {
	foreach test $testfiles {
	    # change next to log/log
	    #io note { io puts ${test}... }
	    Aopen

	    path pipe line {
		io trace {TEST: $line}
		ProcessLine $line
	    } [option get --with-shell] $main $localprefix $test

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

	# Sort by shell and testsuite, re-package into tuples.
	set tmp {}
	foreach k [lsort -dict [dict keys $times]] {
	    lassign $k                   shell suite
	    lassign [dict get $times $k] ntests sec usec
	    lappend tmp [list $shell $suite $ntests $sec $usec]
	}

	# Sort tuples by time per test, and transpose into
	# columns. Add the header and footer lines.

	lappend sh Shell     =====
	lappend ts Testsuite =========
	lappend nt Tests     =====
	lappend ns Seconds   =======
	lappend us uSec/Test =========

	foreach item [lsort -index 4 -decreasing $tmp] {
	    lassign $item shell suite ntests sec usec
	    lappend sh $shell
	    lappend ts $suite
	    lappend nt $ntests
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
	    ntests [strutil padr $nt] \
	    sec    [strutil padr $ns] \
	    usec   [strutil padr $us] {
	    Stream summary "$shell $suite $ntests $sec $usec"
	}
    }

    StreamsDone

    # Report ok/fail
    status [dict get $state status]
    return
}

proc ::kettle::Test::ProcessLine {line} {
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
    Testsuite;NoTestsuite
    Support;Testing
    Summary

    CaptureFailureSync            ; # cap/state: sync => body
    CaptureFailureCollectBody     ; # cap/state: body => actual|error
    CaptureFailureCollectActual   ; # cap/state: actual   => expected
    CaptureFailureCollectExpected ; # cap/state: expected => none
    CaptureFailureCollectError    ; # cap/state: error    => expected

    CaptureStackStart
    CaptureStack

    TestStart;TestSkipped;TestPassed;TestFailed ; # cap/state => sync

    #SetupError
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

proc ::kettle::Test::LogF {text} {
    if {[option get --log-mode] ne "full"} return
    io puts $text
    return
}

proc ::kettle::Test::LogC {text} {
    if {[option get --log-mode] ne "compact"} return
    io puts $text
    return
}

proc ::kettle::Test::Log* {text} {
    io puts $text
    return
}

proc ::kettle::Test::Aopen {} {
    if {[option get --log-mode] ne "compact"} return
    io animation begin
    return
}

proc ::kettle::Test::Aclose {text} {
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

proc ::kettle::Test::Aextend {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation indent $text
    io animation write  ""
    return
    
}

proc ::kettle::Test::Awrite {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation write $text
    return
}

# # ## ### ##### ######## ############# #####################
# Log streams ....

proc ::kettle::Test::Streams {} {
    expr {[option get --log] ne {}}
}

proc ::kettle::Test::Stream {name text} {
    variable stream
    {*}[dict get $stream $name] $text
    return
}

proc ::kettle::Test::StreamsBegin {} {
    variable stream
    variable streams

    if {[option get --log] ne {}} {
	# Log file (stem) specified, generate all log streams.
	# Creation is defered until actual use.
	set stem [option get --log]
	foreach name $streams {
	    dict set stream $name \
		[list ::kettle::Test::StreamsMake $stem $name]
	}
    } else {
	# Without stem we generate no streams.
	dict set stream log ::kettle::io::puts
	foreach name $streams {
	    dict set stream $name ::kettle::Test::StreamsNull
	}
    }
}

proc ::kettle::Test::StreamsDone {} {
    variable stream
    dict for {name cmd} $stream {
	if {[lindex $cmd 0] ne "::puts"} continue
	close [lindex $cmd 1]
    }
    return
}

# Writer for log streams. Create on demand, on first write.
proc ::kettle::Test::StreamsMake {stem name text} {
    variable stream
    file mkdir [file dirname $stem.$name]
    dict set stream $name [list ::puts [open $stem.$name w]]
    Stream $name $text
    return
}

# Writer for disabled streams, doing nothing.
proc ::kettle::Test::StreamsNull {args} {}

# # ## ### ##### ######## ############# #####################

proc ::kettle::Test::InitState {} {
    upvar 1 state state
    # The counters are all updated in ProcessLine.
    # The status may change to 'fail' in ProcessLine.
    set state {
	ctotal   0
	cpassed  0
	cskipped 0
	cfailed  0
	cerrors  0

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

proc ::kettle::Test::Host {} {
    upvar 1 line line state state
    if {![regexp "^@@ Host (.*)$" $line -> host]} return
    #Aextend $host
    #LogC "Host     $host"
    dict set state host $host
    # FUTURE: Write tests results to a storage back end for analysis.
    return -code return
}

proc ::kettle::Test::Platform {} {
    upvar 1 line line state state
    if {![regexp "^@@ Platform (.*)$" $line -> platform]} return
    #LogC "Platform $platform"
    dict set state platform $platform
    #Aextend ($platform)
    return -code return
}

proc ::kettle::Test::Cwd {} {
    upvar 1 line line state state
    if {![regexp "^@@ TestCWD (.*)$" $line -> cwd]} return
    #LogC "Cwd      [path relativecwd $cwd]"
    dict set state cwd $cwd
    return -code return
}

proc ::kettle::Test::Shell {} {
    upvar 1 line line state state
    if {![regexp "^@@ Shell (.*)$" $line -> shell]} return
    #LogC "Shell    $shell"
    dict set state shell $shell
    #Aextend [file tail $shell]
    return -code return
}

proc ::kettle::Test::Tcl {} {
    upvar 1 line line state state
    if {![regexp "^@@ Tcl (.*)$" $line -> tcl]} return
    #LogC "Tcl      $tcl"
    dict set state tcl $tcl
    Aextend "\[$tcl\] "
    return -code return
}

proc ::kettle::Test::Match||Skip||Sourced {} {
    upvar 1 line line state state
    if {[string match "@@ TestDir*"               $line]} {return -code return}
    if {[string match "@@ LocalDir*"              $line]} {return -code return}
    if {[string match "@@ Skip*"                  $line]} {return -code return}
    if {[string match "@@ Match*"                 $line]} {return -code return}
    if {[string match "Sourced * Test Files."     $line]} {return -code return}
    if {[string match "Files with failing tests*" $line]} {return -code return}
    if {[string match "Number of tests skipped*"  $line]} {return -code return}
    if {[string match "\[0-9\]*"                  $line]} {return -code return}
    if {[string match "*error: test failed:*"     $line]} {return -code return}
    return
}

proc ::kettle::Test::Start {} {
    upvar 1 line line state state
    if {![regexp "^@@ Start (.*)$" $line -> start]} return
    #LogC "Start    [clock format $start]"
    dict set state start $start
    dict set state testnum 0
    return -code return
}

proc ::kettle::Test::End {} {
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

proc ::kettle::Test::Testsuite {} {
    upvar 1 line line state state ; variable xfile
    if {![regexp "^@@ Testsuite (.*)$" $line -> file]} return
    #LogC "Test $file"
    dict set state file $file
    Aextend "[file tail $file] "
    return -code return
}

proc ::kettle::Test::NoTestsuite {} {
    upvar 1 line line state state
    if {![string match "Error:  No test files remain after*" $line]} return
    dict set state suite/status none
    Aclose {No tests}
    return -code return
}

proc ::kettle::Test::Support {} {
    upvar 1 line line state state
    #Awrite "S $package" /when caught
    #if {[regexp "^SYSTEM - (.*)$" $line -> package]} {LogC "Ss $package";return -code return}
    #if {[regexp "^LOCAL  - (.*)$" $line -> package]} {LogC "Sl $package";return -code return}
    if {[regexp "^SYSTEM - (.*)$" $line -> package]} {return -code return}
    if {[regexp "^LOCAL  - (.*)$" $line -> package]} {return -code return}
    return

}

proc ::kettle::Test::Testing {} {
    upvar 1 line line state state
    #Awrite "T $package" /when caught
    #if {[regexp "^SYSTEM % (.*)$" $line -> package]} {LogC "Ts $package";return -code return}
    #if {[regexp "^LOCAL  % (.*)$" $line -> package]} {LogC "Tl $package";return -code return}
    if {[regexp "^SYSTEM % (.*)$" $line -> package]} {return -code return}
    if {[regexp "^LOCAL  % (.*)$" $line -> package]} {return -code return}
    return
}

proc ::kettle::Test::Summary {} {
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

proc ::kettle::Test::TestStart {} {
    upvar 1 line line state state
    if {![string match {---- * start} $line]} return
    set testname [string range $line 5 end-6]
    Awrite "---- $testname"
    dict set state test $testname
    dict incr state testnum
    return -code return
}

proc ::kettle::Test::TestSkipped {} {
    upvar 1 line line state state
    if {![string match {++++ * SKIPPED:*} $line]} return
    regexp {^[^ ]* (.*)SKIPPED:.*$} $line -> testname
    set testname [string trim $testname]
    Awrite "SKIP $testname"
    dict set state test {}
    return -code return
}

proc ::kettle::Test::TestPassed {} {
    upvar 1 line line state state
    if {![string match {++++ * PASSED} $line]} return
    set testname [string range $line 5 end-7]
    Awrite "PASS $testname"
    dict set state test {}
    return -code return
}

proc ::kettle::Test::TestFailed {} {
    upvar 1 line line state state
    if {![string match {==== * FAILED} $line]} return
    set testname [lindex [split [string range $line 5 end-7]] 0]
    Awrite "FAIL $testname"
    dict set state suite/status fail

    ## Initialize state machine to capture the test result.
    ## states: none, sync, body, actual, expected, done, error

    dict set state cap/state    sync
    dict set state cap body     {}
    dict set state cap actual   {}
    dict set state cap expected {}
    return -code return
}

proc ::kettle::Test::CaptureFailureSync {} {
    upvar 1 state state
    if {[dict get $state cap/state] ne "sync"} return
    upvar 1 line line
    if {![string match {==== Contents*} $line]} return
    dict set state cap/state body
    return -code return
}

proc ::kettle::Test::CaptureFailureCollectBody {} {
    upvar 1 state state
    if {[dict get $state cap/state] ne "body"} return

    upvar 1 rline line
    if {[string match {---- Result was*} $line]} {
	dict set state cap/state actual
	return -code return
    } elseif {[string match {---- Test generated error*} $line]} {
	dict set state cap/state error
	return -code return
    }

    dict update state cap c {
	dict append c body $line \n
    }

    return -code return
}

proc ::kettle::Test::CaptureFailureCollectActual {} {
    upvar 1 state state
    if {[dict get $state cap/state] ne "actual"} return

    upvar 1 rline line
    if {[string match {---- Result should*} $line]} {
	dict set state cap/state expected
	return -code return
    }

    dict update state cap c {
	dict append c actual $line \n
    }

    return -code return
}

proc ::kettle::Test::CaptureFailureCollectExpected {} {
    upvar 1 state state
    if {[dict get $state cap/state] ne "expected"} return

    upvar 1 rline line
    if {![string match {==== *} $line]} {
	dict update state cap c {
	    dict append c expected $line \n
	}
	return -code return
    }

    if {[Streams]} {
	set test     [dict get $state test]
	set body     [dict get $state cap body]
	set actual   [dict get $state cap actual]
	set expected [dict get $state cap expected]

	Stream faildetails "==== [lrange $test end-1 end] FAILED ========="
	Stream faildetails "==== Contents of test case:\n"		       
	Stream faildetails $body					       
	Stream faildetails "---- Result was:"			       
	Stream faildetails [string range $actual 0 end-1]		       
	Stream faildetails "---- Result should have been:"		       
	Stream faildetails [string range $expected 0 end-1]		       
	Stream faildetails "==== [lrange $test end-1 end] ====\n\n"
    }

    dict unset state cap
    dict set   state cap/state none
    dict set   state test {}
    return -code return
}

proc ::kettle::Test::CaptureFailureCollectError {} {
    upvar 1 state state
    if {[dict get $state cap/state] ne "error"} return

    upvar 1 rline line
    if {[string match {---- errorCode*} $line]} {
	dict set state cap/state expected
	return -code return
    }

    dict update state cap c {
	dict append c actual $line \n
    }
    return -code return
}

proc ::kettle::Test::CaptureStackStart {} {
    upvar 1 line line state state
    if {![string match {@+*} $line]} return

    dict set state cap/stack    on
    dict set state stack        {}
    dict set state suite/status error
    dict incr state cerrors

    Aextend "[io mred {Caught Error}] "
    return -code return
}

proc ::kettle::Test::CaptureStack {} {
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

proc ::kettle::Test::Aborted {} {
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

proc ::kettle::Test::AbortCause {} {
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
