# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle a tcltest-based testsuite

namespace eval ::kettle { namespace export testsuite }

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

	# Test dependencies - building them is not covered here!

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

	set ctotal   0
	set cpassed  0
	set cskipped 0
	set cfailed  0

	path in $testsrcdir {
	    foreach test $testsuite {
		io note { io puts ${test}... }

		path pipe line {

		    # This first draft uses the simple output
		    # processing logic I put into older build.tcl
		    # scripts (pre-kettle). This should be replaced
		    # with the sak.tcl testsuite support found in
		    # tcllib/tklib.

		    # TODO ## test --log option ?
		    #io puts $log $line ; # Full log.

		    if {[string match "++++*"      $line] ||
			[string match "----*start" $line]} {
			# Flash report of activity...
			io interm {
			    io puts -nonewline "\r$line                                  "
			    flush stdout
			}
			io ingui {
			    io puts $line
			}
			continue
		    }

		    # Failed tests are reported immediately, in full.
		    if {[string match {*error: test failed*} $line]} {

			# shorten the shown path for the test file.
			set r [lassign [split $line :] path]
			set line [join [linsert $r 0 [file tail $path]] :]
			set line [string map {{error: test } {}} $line]

			io err {
			    io interm {
				io puts \r$line\t\t
				flush stdout
			    }
			    io ingui {
				io puts $line
			    }
			}
			status fail
			continue
		    }

		    # Collect the statistics (per .test file).
		    if {![string match *Total* $line]} continue

		    lassign $line file _ total _ passed _ skipped _ failed
		    if {$failed}  { set failed  " $failed"  } ; # indent, stand out.
		    if {$skipped} { set skipped " $skipped" } ; # indent, stand out.
		    M add row [list $file $total $passed $skipped $failed]

		    incr ctotal   $total
		    incr cpassed  $passed
		    incr cskipped $skipped
		    incr cfailed  $failed

		} [info nameofexecutable] $test -verbose bpstenl
	    }
	}

	M add row {File Total Passed Skipped Failed}
	M add row [list {} $ctotal $cpassed $cskipped $cfailed]

	io puts "\n"
	io puts [M format 2string]
	io puts ""

    } $root $testsuite

    return
}

# # ## ### ##### ######## ############# #####################
return
