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
    variable status  ok
    variable message {}
}

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::status::check {} {
    variable status
    if {$status eq "ok"} return
    return -code return
}

proc ::kettle::status::ok {} {
    variable status  ok
    variable message {}
    return
}

proc ::kettle::status::fail {{msg {with FAILURES}}} {
    variable status  warn
    variable message $msg
    return
}

proc ::kettle::status::show {} {
    variable status
    variable message
    io ingui {
	io $status {
	    io puts -nonewline DONE
	    if {$message ne {}} {
		io puts " $message"
	    }
	    io puts {}
	}
    }
    return
}

# # ## ### ##### ######## ############# #####################
return

