# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Option handling, sub layer: Types & Validation.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::ovalidate {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## API

proc ::kettle::ovalidate::any {v} { return }

proc ::kettle::ovalidate::boolean {v} {
    if {[string is boolean -strict $v]} return
    Bad "Expected boolean, but got \"$new\""
}

proc ::kettle::ovalidate::rfile {v} {
    if {$v eq {}} return;# default
    if {[file isfile $v] &&
	[file readable $v]} return
    Bad "Expected boolean, but got \"$new\""
}

proc ::kettle::ovalidate::enum {choices v} {
    if {$v in $choices} return
    set c [linsert '[join $choices {', '}]' end-1 or]
    Bad "Expected one of $c, got \"$v\""
}

proc ::kettle::ovalidate::Bad {msg} {
    return -code error -errorcode {KETTLE OPTION VETO} $msg
}

# # ## ### ##### ######## ############# #####################
return
