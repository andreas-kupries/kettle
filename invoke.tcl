# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Invoke goals in other packages in related directories, including itself.

namespace eval ::kettle { namespace export invoke }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::invoke {other args} {

    # Special syntax. Access to named lists of other packages in the
    # option database. Recurse call on each entry.
    if {[string match @* $other]} {
	# TODO: Catch cycles!
	foreach element [option get $other] {
	    invoke $element {*}$args
	}
	return
    }

    # Special syntax. Recursively call goals on self.
    #
    # Similar to recipes and parents, except here the connection is
    # dynamically made, and not statically build as part of the recipe
    # definition.
    #
    # Second difference, the sub-goal(s) run in a separate process,
    # protecting us somewhat, especially if we change the
    # configuration for the sub-goal. This part may not make sense,
    # and may be changed in the future to directly invoke 'recipe run'
    # (see kettle::Application).

    if {$other eq "self"} {
	set buildscript [path script]
	set other       [path sourcedir]
    } else {
	set other [path sourcedir $other]

	if {[file isfile $other]} {
	    # Assume that the provided file is the build script.
	    # Extract the source directory from it.

	    set buildscript $other
	    set other       [file dirname $other]

	} elseif {[file isdirectory $other]} {





	    # Use default name to look for the build file.
	    # FUTURE: Search...

	    set buildscript $other/build.tcl
	} else {
	    return -code error "Path is neither file, nor directory"
	}
    }

    # Filter goals against the global knowledge of those already
    # done. This is a bit more complex as the arguments may contain
    # options, these we do not filter. This is a small two-state
    # state-machine.

    set goals {}
    set keep {}
    set skip 0
    foreach g $args {
	if {$skip} {
	    # option argument, keep, prepare for regular again
	    set skip 0
	    lappend keep $g
	    continue
	} elseif {[string match --* $g]} {
	    # option, keep, and prepare to keep next argument, the
	    # option value
	    set skip 1
	    lappend keep $g
	    continue
	} elseif {[status is $g $other] ne "unknown"} {
	    # goal, already done, ignore (= filtered out)
	    continue
	}
	# goal, not done, keep
	lappend keep $g
	lappend goals $g
    }

    # Ignore call if no goals to run are left.
    if {![llength $keep]} return

    io trace {enter $other $keep}

    # The current configuration (options) is directly specified on the
    # command line, which then might be overridden by the goal's
    # arguments. The work state is transmitted through a temporary
    # file. This is also the one thing which gets loaded back after
    # the sub-process has completed, on account of the sub-process
    # extending it.

    # Notes:
    # - We use our tclsh to run the child.
    # - We use our kettle interpreter to run the child.

    set work   [status save]
    set config [option save]
    try {
	path exec \
	    [info nameofexecutable] \
	    [option get @kettle] \
	    -f $buildscript \
	    --config $config --state $work {*}$keep

	status load $work
    } finally {
	file delete $work
	file delete $config
    }

    # ok/fail is based on the work database we got back.
    # All goals must be ok.

    set ok 1
    foreach goal $goals {
	set state [status is $goal $other]
	io trace {enter result $goal = $state}
	if {$state eq "ok"} continue
	set ok 0
    }

    return $ok
}
