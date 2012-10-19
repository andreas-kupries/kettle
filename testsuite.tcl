# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle a tcltest-based testsuite

namespace eval ::kettle { namespace export testsuite }

# # ## ### ##### ######## ############# #####################
## Shell to run the tests with.
## Irrelevant to work database keying.

kettle option define --with-shell  [info nameofexecutable] {} {
    set! --with-shell [path norm $new]
}
kettle option no-work-key --with-shell

# # ## ### ##### ######## ############# #####################
## Mode and file/channel for test logging.
## Irrelevant to work database keying.

kettle option define --log-mode compact {} {
    if {$new ni {compact raw}} {
	veto "Expected one of 'compact', or 'raw', got \"$new\""
    }
    return
}
kettle option define --log {} {} {
    set! --log [path norm $new]
}

kettle option no-work-key --log-mode
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

    # Dictionary of log streams. Maps names to write command.
    variable stream {}
    # Names of our streams.
    variable streams {
	log summary failures skipped none errdetails faildetails
	timings
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

    LogBegin
    LogE ============================================================

    package require struct::matrix

    struct::matrix M
    M add columns 5
    M add row {File Total Passed Skipped Failed}

    set main [path norm [option get @kettledir]/testmain.tcl]
    InitState

    path in $srcdir {
	foreach test $testfiles {
	    # change next to log/log
	    io note { io puts ${test}... }
	    io animation begin

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
    set fn [dict get $state cfailed]
    set en [dict get $state cerrors]

    set t [format %6d [dict get $state ctotal]]
    set p [format %6d [dict get $state cpassed]]
    set s [format %6d [dict get $state cskipped]]
    set f [format %6d $fn]
    set e [format %6d $en]

    if {$fn} { set f [io mred $f] }
    if {$en} { set e [io mmagenta $e] }

    Log log "Passed  $p of $t"
    Log log "Skipped $s of $t"
    Log log "Failed  $f of $t"
    Log log "#Errors $e"

    if {0} {
    if {$alog} {
	variable xtimes
	array set times $xtimes

	struct::matrix M
	M add columns 6
	foreach k [lsort -dict [array names times]] {
	    M add row [list {*}$k {*}$times($k)]
	}
	M sort rows -decreasing 5

	M insert row 0 {Shell Testsuite Tests Seconds uSec/Test}
	M insert row 1 {===== ========= ===== ======= =========}
	M add    row   {===== ========= ===== ======= =========}

	Log summary \nTimings...
	Log summary [M format 2string]
    }
    }

    LogDone

    # Report ok/fail
    status [dict get $state status]
    return
}

proc ::kettle::Test::ProcessLine {line} {
    # Counters and other state in the calling environment.
    upvar 1 state state

    set line [string trimright $line]

    LogE $line

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

    CaptureFailureSync            ; # cap state: sync => body
    CaptureFailureCollectBody     ; # cap state: body => actual|error
    CaptureFailureCollectActual   ; # cap state: actual   => expected
    CaptureFailureCollectExpected ; # cap state: expected => done
    CaptureFailureCollectError    ; # cap state: error    => expected

    #CaptureStackStart
    #CaptureStack

    TestStart;TestSkipped;TestPassed;TestFailed ; # cap state => sync

    #SetupError
    #Aborted
    #AbortCause

    Match||Skip||Sourced
    # Unknown lines are printed
    #if {!$araw} {puts !$line}











return
    # This first draft uses the simple output
    # processing logic I put into older build.tcl
    # scripts (pre-kettle). This should be replaced
    # with the sak.tcl testsuite support found in
    # tcllib/tklib.

    # TODO ## tests: --log option ?
    #io puts $line ; # Full log.

    if {[string match "++++*"      $line] ||
	[string match "----*start" $line]} {
	# Flash report of activity...
	io for-terminal {
	    io puts -nonewline "[string trimright $line \n]                                  \r"
	    flush stdout
	}
	io for-gui {
	    io puts $line
	}
	return
    }

    # Failed tests are reported immediately, in full.
    if {[string match {*error: test failed*} $line]} {

	# shorten the shown path for the test file.
	set r [lassign [split $line :] path]
	set line [join [linsert $r 0 [file tail $path]] :]
	set line [string map {{error: test } {}} $line]

	io err {
	    io for-terminal {
		io puts \r$line\t\t
		flush stdout
	    }
	    io for-gui {
		io puts $line
	    }
	}
	set status fail
	return
    }

    # Collect the statistics (per .test file).
    if {![string match *Total* $line]} return

    lassign $line file _ total _ passed _ skipped _ failed
    if {$failed}  { set failed  " $failed"  } ; # indent, stand out.
    if {$skipped} { set skipped " $skipped" } ; # indent, stand out.
    M add row [list $file $total $passed $skipped $failed]

    incr ctotal   $total
    incr cpassed  $passed
    incr cskipped $skipped
    incr cfailed  $failed
    return
}

# # ## ### ##### ######## ############# #####################

proc ::kettle::Test::LogE {text} {
    if {[option get --log-mode] eq "compact"} return
    Log log $text
    return
}

proc ::kettle::Test::LogC {text} {
    if {[option get --log-mode] ne "compact"} return
    io puts $text
    return
}

proc ::kettle::Test::Log {name text} {
    variable stream
    {*}[dict get $stream $name] $text
    return
}

proc ::kettle::Test::LogBegin {} {
    variable stream
    variable streams

    if {[option get --log] ne {}} {
	# Log file (stem) specified, generate all log streams.
	set stem [option get --log]
	foreach name $streams {
	    dict set stream $name [list ::puts [open $stem.$name w]]
	}
    } else {
	# Without stem generate only the main log stream and go
	# through the virtualized io so that the gui may see it.
	dict set stream log ::kettle::io::puts
	foreach name $streams {
	    if {$name eq "log"} continue
	    dict set stream $name ::kettle::Test::LogNull
	}
    }
}

proc ::kettle::Test::LogDone {} {
    variable stream
    dict for {name cmd} $stream {
	if {[llength $cmd] < 2} continue
	set ch [lindex $cmd 1]
	if {$ch eq "stdout"} continue
	close $ch
    }
    return
}

# Writer for disabled log streams.
proc ::kettle::Test::LogNull {args} {}

# # ## ### ##### ######## ############# #####################

proc ::kettle::Test::Aclose {text} {
    upvar 1 state state
    if {[option get --log-mode] ne "compact"} return
    io animation last $text

    Log summary $text
    # Maybe use a mapping table here instead, status to stream.
    switch -exact -- [dict get $state suite] {
	error   -
	fail    { Log failures $text }
	none    { Log none     $text }
	aborted { Log skipped  $text }
    }
    return
}

proc ::kettle::Test::Aextend {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation indent " $text"
    io animation write  ""
    return
    
}

# was =
proc ::kettle::Test::Awrite {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation write $text
    return
}

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

	err 0
	suite ok

	cap {state none}
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
    #variable xshell
    #variable maxvl
    #Aextend \[$xtcl\][blank [expr {$maxvl - [string length $xtcl]}]]
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
    dict lappend times $key [list $num $delta $score]

    Log timings [list TIME $key $num $delta $score]
    #variable xshell
    #sak::registry::local set $xshell End $end
    return -code return
}

proc ::kettle::Test::Testsuite {} {
    upvar 1 line line state state ; variable xfile
    if {![regexp "^@@ Testsuite (.*)$" $line -> file]} return

LogC "Test $file"

    #Awrite <[file tail $xfile]>
    dict set state file $file
    return -code return
}

proc ::kettle::Test::NoTestsuite {} {
    upvar 1 line line state state
    if {![string match "Error:  No test files remain after*" $line]} return
    dict set state suite none
    Awrite {No tests}
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

    set thestate [dict get $state suite]

    dict incr state ctotal   $total
    dict incr state cpassed  $passed
    dict incr state cskipped $skipped
    dict incr state cfailed  $failed

    set total   [format %5d $total]
    set passed  [format %5d $passed]
    set skipped [format %5d $skipped]
    set failed  [format %5d $failed]

    if {!$total && ($thestate eq "ok")} {
	dict set state suite none
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
    dict set state suite fail

    ## Initialize state machine to capture the test result.
    ## states: none, sync, body, actual, expected, done, error

    dict set state cap state    sync
    dict set state cap body     {}
    dict set state cap actual   {}
    dict set state cap expected {}
    return -code return
}

proc ::kettle::Test::CaptureFailureSync {} {
    upvar 1 state state
    if {[dict get $state cap state] ne "sync"} return
    upvar 1 line line
    if {![string match {==== Contents*} $line]} return
    dict set state cap state body
    return -code return
}

proc ::kettle::Test::CaptureFailureCollectBody {} {
    upvar 1 state state
    if {[dict get $state cap state] ne "body"} return

    upvar 1 rline line
    if {[string match {---- Result was*} $line]} {
	dict set state cap state actual
	return -code return
    } elseif {[string match {---- Test generated error*} $line]} {
	dict set state cap state error
	return -code return
    }

    set v [dict get $state cap body]
    append v $line \n
    dict set state cap body $v

    return -code return
}

proc ::kettle::Test::CaptureFailureCollectActual {} {
    upvar 1 state state
    if {[dict get $state cap state] ne "actual"} return

    upvar 1 rline line
    if {[string match {---- Result should*} $line]} {
	dict set state cap state expected
	return -code return
    }

    set v [dict get $state cap actual]
    append v $line \n
    dict set state cap actual $v

    return -code return
}

proc ::kettle::Test::CaptureFailureCollectExpected {} {
    upvar 1 state state
    if {[dict get $state cap state] ne "expected"} return

    upvar 1 rline line
    if {![string match {==== *} $line]} {
	set v [dict get $state cap expected]
	append v $line \n
	dict set state cap expected $v
	return -code return
    }

    variable alog
    if {$alog} {
	set test     [dict get $state test]
	set body     [dict get $state cap body]
	set actual   [dict get $state cap actual]
	set expected [dict get $state cap expected]

	Log faildetails "==== [lrange $test end-1 end] FAILED ========="
	Log faildetails "==== Contents of test case:\n"		       
	Log faildetails $body					       
	Log faildetails "---- Result was:"			       
	Log faildetails [string range $actual 0 end-1]		       
	Log faildetails "---- Result should have been:"		       
	Log faildetails [string range $expected 0 end-1]		       
	Log faildetails "==== [lrange $test end-1 end] ====\n\n"
    }

    dict unset state cap
    dict set   state cap state none
    dict set   state test {}
    return -code return
}

proc ::kettle::Test::CaptureFailureCollectError {} {
    upvar 1 state state
    if {[dict get $state cap state] ne "error"} return

    upvar 1 rline line
    if {[string match {---- errorCode*} $line]} {
	dict set state cap state expected
	return -code return
    }

    set v [dict get $state cap actual]
    append v $line \n
    dict set state cap actual $v

    return -code return
}

proc ::kettle::Test::CaptureStackStart {} {
    upvar 1 line line state state
    if {![string match {@+*} $line]} return
    variable xstackcollect 1
    variable xstack        {}
    variable xstatus       error
    Awrite {Error, capturing stacktrace}
    return -code return
}

proc ::kettle::Test::CaptureStack {} {
    variable xstackcollect
    if {!$xstackcollect} return
    upvar 1 line line state state
    variable xstack
    if {![string match {@-*} $line]} {
	append xstack [string range $line 2 end] \n
    } else {
	set xstackcollect 0
	variable xfile
	variable alog
	#sak::registry::local set $xfile Stacktrace $xstack
	if {$alog} {
	    variable logerd
	    puts  $logerd "[lindex $xfile end] StackTrace"
	    puts  $logerd "========================================"
	    puts  $logerd $xstack
	    puts  $logerd "========================================\n\n"
	    flush $logerd
	}
    }
    return -code return
}

proc ::kettle::Test::Aborted {} {
    upvar 1 line line state state
    if {![string match {Aborting the tests found *} $line]} return
    # Ignore aborted status if we already have it, or some other error
    # status (like error, or fail). These are more important to show.
    if {[dict get $state suite] eq "ok"} {dict set state suite aborted}
    Awrite Aborted
    return -code return
}

proc ::kettle::Test::AbortCause {} {
    upvar 1 line line state state
    if {
	![string match {Requir *}   $line] &&
	![string match {Error in *} $line]
    } return ; # {}
    Awrite $line
    return -code return
}

proc ::kettle::Test::SetupError {} {
    upvar 1 line line state state
    if {![string match {SETUP Error*} $line]} return
    dict set state suite error
    Awrite {Setup error}
    return -code return
}

# ###
# ###

namespace eval ::kettle::Test {
    # State of test processing. ... TODO: Goes into a dictionary in 'Run'.

    variable xstackcollect 0
    variable xstack    {}
    #variable xcollect  0
    #variable xbody     {}
    #variable xactual   {}
    #variable xexpected {}
    #variable xtimes     {}

    variable xstatus ok ;# none, aborted, error, fail
    # --> state suite

    # Max length of module names and patchlevel information.

    variable maxml 0
    variable maxvl 0
}

# # ## ### ##### ######## ############# #####################
return
