# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Invoke goals in other packages in related directories, including itself.

namespace eval ::kettle { namespace export invoke }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::invoke {othersrc args} {
    if {$othersrc eq "self"} {
	set othersrc [path script]
    } else {
	set othersrc [path norm $othersrc]
    }

    if {[file isfile $othersrc]} {
	# Assume that the provided file is the build script.
	# Get the actual directory from that.

	set buildscript $othersrc
	set othersrc    [file dirname $othersrc]

    } elseif {[file isdirectory $othersrc]} {
	# Use default name to look for the build file.
	# FUTURE: Search...

	set buildscript $othersrc/build.tcl
    } else {
	return -code error "Path is neither file, nor directory"
    }

    # Filter goals against the global knowledge of those already done.

    # Note that the local options are separated from the arguments
    # because we have to ensure that their current values are restored
    # when loading the sub-process' state back. And we to reload the
    # state because the sub-process may have extended it (Especially
    # the work database for the executed goals). Here the list of
    # overrides comes into play. These are the options which were
    # changed for the sub-process and must not change for ourselves.

    set keep {}
    set skip 0
    set overrides {}

    foreach g $args {
	if {$skip} {
	    set skip 0
	    lappend keep $g
	    continue
	}
	if {[string match -* $g]} {
	    set skip 1
	    lappend keep $g
	    lappend overrides $g
	    continue
	}

	if {[status is $g $othersrc] ne "unknown"} continue
	lappend keep $g
    }
    # Ignore calls without goals to run.
    if {![llength $keep]} return

    io trace {enter $othersrc $keep}

    set tmp [option save]

    path exec $buildscript --state $tmp {*}$keep

    option load $tmp $overrides
    file delete $tmp

    # ok/fail is based on the work database we got back.
    set state [status is $goal $othersrc]

    io trace {enter result = $state}
    return [expr {$state  eq "ok"}]
}
