# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle a tcltest-based benchmarks

namespace eval ::kettle { namespace export benchmarks }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::benchmarks {{benchsrcdir tests}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::benchmarks args {}

    set root [path sourcedir $benchsrcdir]

    io trace {}
    io trace {SCAN tclbench benchmarks @ $benchsrcdir/}

    if {![file exists $root]} {
	io trace {  NOT FOUND}
	return
    }

    # Heuristic search for benchmarks

    set benchmarks {}
    path foreach-file $root path {
	set spath [path strip $path $root]

	if {[catch {
	    path tcltest-file $path
	} abench]} {
	    io err { io puts stderr "    Skipped: $benchsrcdir/$spath @ $adia" }
	    continue
	}
	if {!$abench} continue

	io trace {    Accepted: $benchsrcdir/$spath}

	lappend benchmarks $spath
    }

    if {![llength $benchmarks]} return

    # Put the benchmarks into recipes.

    recipe define test {
	Run the benchmarks
    } {benchsrcdir benchmarks} {

	# TODO ####

    } $root $benchmarks

    return
}

# # ## ### ##### ######## ############# #####################
return
