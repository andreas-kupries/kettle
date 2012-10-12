# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## General goal status handling

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::status {
    namespace export {[a-z]*}
    namespace ensemble create

    namespace import ::kettle::io
}

# # ## ### ##### ######## ############# #####################
## State

namespace eval ::kettle::status {
    # Stack of currently executing goals.
    variable current {}

    # Dictionary holding the status of all goals executed.
    variable work {}
}

# # ## ### ##### ######## ############# #####################
## API.
##
## Note: The database keys contain the source-dir (normalized absolute
## path) to make the data shareable across multiple kettle instances
## calling on each other. This, the location in the key, makes the
## goals properly distinguishable.

proc ::kettle::status::begin {goal} {
    variable current
    variable work

    set key [kettle path sourcedir]|$goal

    if {[dict exists $work $key]} {
	set status [dict get $work $key]
	# ok/fail for the goal -> do not run it again.
	if {$status ne "@work"} {
	    io trace {RUN ($goal) ... DONE ALREADY, STOP}
	    return -code return
	}

	# goal still at work -> found a cycle of goals calling
	# themselves recursively.

	return -code error -errorcode {KETTLE STATUS CYCLE} \
	    "Cycle in goal definitions: $goal"
	# TODO: Determine full set of goals @work.
    }

    # goal has not run yet. Mark for work, reset overall state, and
    # save work database back to the configuration.

    dict set work $key state @work
    dict set work $key msg   {}

    lappend current $goal
    return
}

proc ::kettle::status::ok {} {
    variable current
    variable work

    set key     [kettle path sourcedir]|[lindex $current end]
    set current [lreplace $current end end]

    dict set work $key state ok
    dict set work $key msg   OK

    return -errorcode {KETTLE STATUS OK} -code error ""
}

proc ::kettle::status::fail {{msg FAIL}} {
    variable current
    variable work

    set key     [kettle path sourcedir]|[lindex $current end]
    set current [lreplace $current end end]

    dict set work $key state fail
    dict set work $key msg $msg

    return -errorcode {KETTLE STATUS FAIL} -code error ""
}

proc ::kettle::status::show {goal} {
    variable work

    set key   [kettle path sourcedir]|$goal
    set state [dict get $work $key state]
    set msg   [dict get $work $key msg]

    # Do nothing if the goal is in the works.
    # This means some internal error bubbled past us
    # and we have no reliable status
    if {$state ni {ok fail}} return

    io ingui {
	io $state { io puts $msg }
    }
    io interm {
	if {$state ne "ok"} {
	    io $state { io puts $msg }
	}
    }
    return
}

proc ::kettle::status::is {goal {src {}}} {
    variable work
    # possible results: unknown|ok|fail|work

    if {$src eq {}} { set src [kettle path sourcedir] }
    set key $src|$goal

    if {![dict exists $work $key state]} {
	return unknown
    }

    return [dict get $work $key state]
}

proc ::kettle::status::save {} {
    variable work
    set data ""
    dict for {k v} $work {
	append data @[list $k $v]\n
    }
    return $data
}

# # ## ### ##### ######## ############# #####################
return

