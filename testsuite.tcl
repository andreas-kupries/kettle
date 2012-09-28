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

    } $root $testsuite

    return
}

# # ## ### ##### ######## ############# #####################
return
