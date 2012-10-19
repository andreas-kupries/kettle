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
    set  --log raw
    # When logging to files the main stream is a full log.
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

	    path pipe line {
		io trace {TEST: $line}
		ProcessLine $line
	    } [option get --with-shell] $main $localprefix $test

	    io for-terminal {
		io puts "\r                                               "
	    }
	}
    }




    #M add row {File Total Passed Skipped Failed}
    #M add row [list {} $ctotal $cpassed $cskipped $cfailed]

    #io puts "\n"
    #io puts [M format 2string]
    #io puts ""

    LogDone

    if {0} {


    puts $logext "Passed  [format %6d $pass] of [format %6d $total]"
    puts $logext "Skipped [format %6d $skip] of [format %6d $total]"

    if {$fail} {
	puts $logext "Failed  [red][format %6d $fail][rst] of [format %6d $total]"
    } else {
	puts $logext "Failed  [format %6d $fail] of [format %6d $total]"
    }
    if {$err} {
	puts $logext "#Errors [mag][format %6d $err][rst]"
    } else {
	puts $logext "#Errors [format %6d $err]"
    }

    if {$alog} {
	variable xtimes
	array set times $xtimes

	struct::matrix M
	M add columns 6
	foreach k [lsort -dict [array names times]] {
	    #foreach {shell module testfile} $k break
	    foreach {testnum delta score} $times($k) break
	    M add row [linsert $k end $testnum $delta $score]
	}
	M sort rows -decreasing 5

	M insert row 0 {Shell Module Testsuite Tests Seconds uSec/Test}
	M insert row 1 {===== ====== ========= ===== ======= =========}
	M add    row   {===== ====== ========= ===== ======= =========}

	puts $logsum \nTimings...
	puts $logsum [M format 2string]
    }


    }

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
    #Testsuite;NoTestsuite
    #Support;Testing;Other
    #Summary
    #CaptureFailureSync            ; # xcollect 1 => 2
    #CaptureFailureCollectBody     ; # xcollect 2 => 3 => 5
    #CaptureFailureCollectActual   ; # xcollect 3 => 4
    #CaptureFailureCollectExpected ; # xcollect 4 => 0
    #CaptureFailureCollectError    ; # xcollect 5 => 0
    #CaptureStackStart
    #CaptureStack

    #TestStart
    #TestSkipped
    #TestPassed
    #TestFailed                    ; # xcollect => 1

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
    Log log $text
    return
}

# was =|
proc ::kettle::Test::Aclose {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation last $text

    Log summary $text
    # Maybe use a mapping table here instead, status to stream.
    switch -exact -- [dict get $state suite] {
	error   -
	fail    { Log failures $string }
	none    { Log none     $string }
	aborted { Log skipped  $string }
    }
    return
}

# was +=
proc ::kettle::Test::Aextend {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation index " $text"
    io animation write ""
    return
    
}

# was =
proc ::kettle::Test::Awrite {text} {
    if {[option get --log-mode] ne "compact"} return
    io animation write $text
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

proc ::kettle::Test::InitState {} {
    upvar 1 state state
    # The counters are all updated in ProcessLine.
    # The status may change to 'fail' in ProcessLine.
    set state {
	ctotal   0 
	cpassed  0 
	cskipped 0 
	cfailed  0 
	status   ok

	host     {}
	platform {}
	cwd      {}
	shell    {}
	file     {}
	test     {}
	start    {}
	times    {}

	suite ok
    }
    return
}

proc ::kettle::Test::Host {} {
    upvar 1 line line state state
    if {![regexp "^@@ Host (.*)$" $line -> host]} return
    # Aextend $host
    LogC "Host     $host"
    dict set state host $host
    # FUTURE: Write tests results to a storage back end.
    #sak::registry::local set [list Tests Results $xhost]
    return -code return
}

proc ::kettle::Test::Platform {} {
    upvar 1 line line state state
    if {![regexp "^@@ Platform (.*)$" $line -> platform]} return
    LogC "Platform $platform"
    dict set state platform $platform
    # Aextend ($platform)
    #sak::registry::local set $xhost Platform $xplatform
    return -code return
}

proc ::kettle::Test::Cwd {} {
    upvar 1 line line state state
    if {![regexp "^@@ TestCWD (.*)$" $line -> cwd]} return
    LogC "Cwd      [path relativecwd $cwd]"
    dict set state cwd $cwd
    #set xcwd [linsert $xhost end $xcwd]
    #sak::registry::local set $xcwd
    return -code return
}

proc ::kettle::Test::Shell {} {
    upvar 1 line line state state
    if {![regexp "^@@ Shell (.*)$" $line -> shell]} return
    LogC "Shell    $shell"
    dict set state shell $shell
    # Aextend [file tail $shell]
    #set xshell [linsert $xcwd end $xshell]
    #sak::registry::local set $xshell
    return -code return
}

proc ::kettle::Test::Tcl {} {
    upvar 1 line line state state
    if {![regexp "^@@ Tcl (.*)$" $line -> tcl]} return
    LogC "Tcl      $tcl"
    dict set state tcl $tcl
    #variable xshell
    #variable maxvl
    #Aextend \[$xtcl\][blank [expr {$maxvl - [string length $xtcl]}]]
    #sak::registry::local set $xshell Tcl $xtcl
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
    LogC "Start    [clock format $start]"
    dict set state start $start
    dict set state testnum 0
    #sak::registry::local set $xshell Start $start
    return -code return
}

proc ::kettle::Test::End {} {
    upvar 1 line line state state
    if {![regexp "^@@ End (.*)$" $line -> end]} return

    set start [dict get $state start]
    set shell [dict get $state shell]
    set file  [dict get $state file]
    set num   [dict get $state testnum]

    LogC "Started  [clock format $start]"
    LogC "End      [clock format $end]"

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
    #= <[file tail $xfile]>
    dict set state file $file
    #sak::registry::local set $xfile Aborted 0
    return -code return
}

proc ::kettle::Test::NoTestsuite {} {
    upvar 1 line line state state
    if {![string match "Error:  No test files remain after*" $line]} return
    dict set state suite none
    = {No tests}
    return -code return
}

proc ::kettle::Test::Support {} {
    upvar 1 line line state state
    if {![regexp "^- (.*)$" $line -> package]} return
    #= "S $package"
    foreach {pn pv} $package break
    variable xfile
    #sak::registry::local set [linsert $xfile end Support] $pn $pv
    return -code return
}

proc ::kettle::Test::Testing {} {
    upvar 1 line line state state
    if {![regexp "^\\* (.*)$" $line -> package]} return
    #= "T $package"
    foreach {pn pv} $package break
    variable xfile
    #sak::registry::local set [linsert $xfile end Testing] $pn $pv
    return -code return
}

proc ::kettle::Test::Other {} {
    upvar 1 line line state state
    if {![string match ">*" $line]} return
    return -code return
}

proc ::kettle::Test::Summary {} {
    upvar 1 line line state state
    if {![regexp "^all\\.tcl:(.*)$" $line -> line]} return
    variable xmodule
    variable xstatus
    variable xvstatus
    foreach {_ t _ p _ s _ f} [split [string trim $line]] break
    #sak::registry::local set $xmodule Total   $t ; set t [format %5d $t]
    #sak::registry::local set $xmodule Passed  $p ; set p [format %5d $p]
    #sak::registry::local set $xmodule Skipped $s ; set s [format %5d $s]
    #sak::registry::local set $xmodule Failed  $f ; set f [format %5d $f]

    upvar 2 total _total ; incr _total $t
    upvar 2 pass  _pass  ; incr _pass  $p
    upvar 2 skip  _skip  ; incr _skip  $s
    upvar 2 fail  _fail  ; incr _fail  $f
    upvar 2 err   _err

    set t [format %5d $t]
    set p [format %5d $p]
    set s [format %5d $s]
    set f [format %5d $f]

    if {$xstatus == "ok" && $t == 0} {
	set xstatus none
    }

    set st $xvstatus($xstatus)

    if {$xstatus == "ok"} {
	# Quick return for ok suite.
	Aclose "~~ $st T $t P $p S $s F $f"
	return -code return
    }

    # Clean out progress display using a non-highlighted
    # string. Prevents the char couint from being off. This is
    # followed by construction and display of the highlighted version.

    = "   $st T $t P $p S $s F $f"
    switch -exact -- $xstatus {
	none    {Aclose "~~ [yel]$st T $t[rst] P $p S $s F $f"}
	aborted {Aclose "~~ [whi]$st[rst] T $t P $p S $s F $f"}
	error   {
	    Aclose "~~ [mag]$st[rst] T $t P $p S $s F $f"
	    incr _err
	}
	fail    {Aclose "~~ [red]$st[rst] T $t P $p S $s [red]F $f[rst]"}
    }
    return -code return
}

proc ::kettle::Test::TestStart {} {
    upvar 1 line line state state
    if {![string match {---- * start} $line]} return
    set testname [string range $line 5 end-6]
    = "---- $testname"
    variable xfile
    variable xtest [linsert $xfile end $testname]
    variable xtestnum
    incr     xtestnum
    return -code return
}

proc ::kettle::Test::TestSkipped {} {
    upvar 1 line line state state
    if {![string match {++++ * SKIPPED:*} $line]} return
    regexp {^[^ ]* (.*)SKIPPED:.*$} $line -> testname
    set              testname [string trim $testname]
    variable xtest
    = "SKIP $testname"
    if {$xtest == {}} {
	variable xfile
	set xtest [linsert $xfile end $testname]
    }
    #sak::registry::local set $xtest Status Skip
    set xtest {}
    return -code return
}

proc ::kettle::Test::TestPassed {} {
    upvar 1 line line state state
    if {![string match {++++ * PASSED} $line]} return
    set             testname [string range $line 5 end-7]
    variable xtest
    = "PASS $testname"
    if {$xtest == {}} {
	variable xfile
	set xtest [linsert $xfile end $testname]
    }
    #sak::registry::local set $xtest Status Pass
    set xtest {}
    return -code return
}

proc ::kettle::Test::TestFailed {} {
    upvar 1 line line state state
    if {![string match {==== * FAILED} $line]} return
    set        testname [lindex [split [string range $line 5 end-7]] 0]
    = "FAIL $testname"
    variable xtest
    if {$xtest == {}} {
	variable xfile
	set xtest [linsert $xfile end $testname]
    }
    #sak::registry::local set $xtest Status Fail
    ## CAPTURE INIT
    variable xcollect  1
    variable xbody     ""
    variable xactual   ""
    variable xexpected ""
    variable xstatus   fail
    # Ignore failed status if we already have it, or an error
    # status. The latter is more important to show. We do override
    # status 'aborted'.
    if {$xstatus == "ok"}      {set xstatus fail}
    if {$xstatus == "aborted"} {set xstatus fail}
    return -code return
}

proc ::kettle::Test::CaptureFailureSync {} {
    variable xcollect
    if {$xcollect != 1} return
    upvar 1 line line state state
    if {![string match {==== Contents*} $line]} return
    set xcollect 2
    return -code return
}

proc ::kettle::Test::CaptureFailureCollectBody {} {
    variable xcollect
    if {$xcollect != 2} return
    upvar 1 rline line
    variable xbody
    if {[string match {---- Result was*} $line]} {
	set xcollect 3
	return -code return
    } elseif {[string match {---- Test generated error*} $line]} {
	set xcollect 5
	return -code return
    }

    variable xbody
    append   xbody $line \n
    return -code return
}

proc ::kettle::Test::CaptureFailureCollectActual {} {
    variable xcollect
    if {$xcollect != 3} return
    upvar 1 rline line
    if {![string match {---- Result should*} $line]} {
	variable xactual
	append   xactual $line \n
    } else {
	set xcollect 4
    }
    return -code return
}

proc ::kettle::Test::CaptureFailureCollectExpected {} {
    variable xcollect
    if {$xcollect != 4} return
    upvar 1 rline line
    if {![string match {==== *} $line]} {
	variable xexpected
	append   xexpected $line \n
    } else {
	variable alog
	if {$alog} {
	    variable logfad
	    variable xtest
	    variable xbody
	    variable xactual
	    variable xexpected

	    puts  $logfad "==== [lrange $xtest end-1 end] FAILED ========="
	    puts  $logfad "==== Contents of test case:\n"
	    puts  $logfad $xbody

	    puts  $logfad "---- Result was:"
	    puts  $logfad [string range $xactual 0 end-1]

	    puts  $logfad "---- Result should have been:"
	    puts  $logfad [string range $xexpected 0 end-1]

	    puts  $logfad "==== [lrange $xtest end-1 end] ====\n\n"
	    flush $logfad
	}
	set xcollect 0
	#sak::registry::local set $xtest Body     $xbody
	#sak::registry::local set $xtest Actual   $xactual
	#sak::registry::local set $xtest Expected $xexpected
	set xtest {}
    }
    return -code return
}

proc ::kettle::Test::CaptureFailureCollectError {} {
    variable xcollect
    if {$xcollect != 5} return
    upvar 1 rline line
    variable xbody
    if {[string match {---- errorCode*} $line]} {
	set xcollect 4
	return -code return
    }

    variable xactual
    append   xactual $line \n
    return -code return
}

proc ::kettle::Test::Aborted {} {
    upvar 1 line line state state
    if {![string match {Aborting the tests found *} $line]} return
    variable xfile
    variable xstatus
    # Ignore aborted status if we already have it, or some other error
    # status (like error, or fail). These are more important to show.
    if {$xstatus == "ok"} {set xstatus aborted}
    = Aborted
    #sak::registry::local set $xfile Aborted {}
    return -code return
}

proc ::kettle::Test::AbortCause {} {
    upvar 1 line line state state
    if {
	![string match {Requiring *} $line] &&
	![string match {Error in *} $line]
    } return ; # {}
    variable xfile
    = $line
    #sak::registry::local set $xfile Aborted $line
    return -code return
}

proc ::kettle::Test::CaptureStackStart {} {
    upvar 1 line line state state
    if {![string match {@+*} $line]} return
    variable xstackcollect 1
    variable xstack        {}
    variable xstatus       error
    = {Error, capturing stacktrace}
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

proc ::kettle::Test::SetupError {} {
    upvar 1 line line state state
    if {![string match {SETUP Error*} $line]} return
    variable xstatus error
    = {Setup error}
    return -code return
}

# ###
# ###

namespace eval ::kettle::Test {
    # State of test processing. ... TODO: Goes into a dictionary in 'Run'.

    variable xstackcollect 0
    variable xstack    {}
    variable xcollect  0
    variable xbody     {}
    variable xactual   {}
    variable xexpected {}
    #variable xhost     {}
    #variable xplatform {}
    #variable xcwd      {}
    #variable xshell    {}
    #--removed--variable xmodule   {}
    #variable xfile     {}
    variable xtest     {}
    #variable xstartfile {}
    #variable xtimes     {}

    variable xstatus ok ;# none, aborted, error, fail
    # --> state suite

    # Animation prefix of test processing, and flag controlling the
    # nature of logging (raw vs animation).

    variable aprefix   {}
    variable araw      0

    # Max length of module names and patchlevel information.

    variable maxml 0
    variable maxvl 0

    # Map from internal stati to the displayed human readable
    # strings. This includes the trailing whitespace needed for
    # vertical alignment.

    variable  xvstatus
    array set xvstatus {
	ok      {     }
	none    {None }
	aborted {Skip }
	error   {ERR  }
	fail    {FAILS}
    }
}

# # ## ### ##### ######## ############# #####################
return
