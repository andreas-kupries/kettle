# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle a tcltest-based testsuite

namespace eval ::kettle { namespace export testsuite }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::testsuite {{testsrcdir tests}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::testsuite args {}

    set root [path sourcedir $testsrcdir]

    io trace {}
    io trace {SCAN tcltest testsuite @ $testsrcdir/}

    if {![file exists $root]} {
	io trace {  NOT FOUND}
	return
    }

    # Heuristic search for testsuite

    set testsuite {}
    path foreach-file $root path {
	set spath [path strip $path $root]

	if {[catch {
	    path tcltest-file $path
	} atest]} {
	    io err { io puts stderr "    Skipped: $testsrcdir/$spath @ $adia" }
	    continue
	}
	if {!$atest} continue

	io trace {    Accepted: $testsrcdir/$spath}

	lappend testsuite $spath
    }

    if {![llength $testsuite]} return

    # Put the testsuite into recipes.

    recipe define test {
	Run the testsuite
    } {testsrcdir testsuite} {
	# TODO ####

	# run each test file in a separate sub process, to catch
	# crashes and the like ...  assume that the test is self
	# contained in terms of loading tcltest, utilities, and the
	# like.

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

		# path pipe - handle continue/break
		# io - handle \r in GUI - possibly ignore

		path pipe line {

		    # First draft using the simple logic I used in
		    # older build.tcl scripts (pre-kettle). This
		    # should be replaced with the sak.tcl testsuite
		    # support found in tcllib/tklib.

		    # TODO ## --log option ?
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
