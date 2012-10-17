# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle a tcltest-based testsuite

namespace eval ::kettle { namespace export testsuite }

# # ## ### ##### ######## ############# #####################
## Shell to run the tests with.
## Irrelevant to work database keying.

kettle option define --with-shell {} { set! --shell [path norm $new] }
kettle option setd   --with-shell [info nameofexecutable]

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

    package require struct::matrix

    struct::matrix M
    M add columns 5
    M add row {File Total Passed Skipped Failed}

    set ctotal   0  ; # These counteres are all updated in
    set cpassed  0  ; # ProcessLine.
    set cskipped 0  ; #
    set cfailed  0  ; #
    set status   ok ; # May change to 'fail' in ProcessLine.

    set main [path norm [option get @kettledir]/testmain.tcl]

    path in $srcdir {
	foreach test $testfiles {
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

    M add row {File Total Passed Skipped Failed}
    M add row [list {} $ctotal $cpassed $cskipped $cfailed]

    io puts "\n"
    io puts [M format 2string]
    io puts ""

    # Report ok/fail
    status $status
    return
}

proc ::kettle::Test::ProcessLine {line} {
    # Counters and other state in the calling environment.
    upvar 1 ctotal ctotal cpassed cpassed \
	cskipped cskipped cfailed cfailed \
	status status

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
return
