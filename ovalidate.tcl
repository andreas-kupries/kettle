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

proc ::kettle::ovalidate::Def {name script {label {}}} {
    if {$label eq {}} { set label $name }

    namespace eval ::kettle::ovalidate::${name} {
	namespace export help check
	namespace ensemble create
    }
    proc ::kettle::ovalidate::${name}::check {v} $script
    proc ::kettle::ovalidate::${name}::help  {} [list return $label]
    return
}

# # ## ### ##### ######## ############# #####################
## API

proc ::kettle::ovalidate::enum {choices cmd args} {
    Enum::${cmd} $choices {*}$args
}

namespace eval ::kettle::ovalidate::Enum {}

proc ::kettle::ovalidate::Enum::check {choices v} {
    if {$v in $choices} return
    set c [linsert '[join $choices {', '}]' end-1 or]
    Bad "Expected one of $c, got \"$v\""
}

proc ::kettle::ovalidate::Enum::help {choices} {
    return [join $choices |]
}

apply {{} {
    Def any    return
    Def string return
    Def path   return
    Def rpath  return relative/path

    Def boolean {
	if {[string is boolean -strict $v]} return
	Bad "Expected boolean, but got \"$new\""
    }

    Def rfile {
	if {$v eq {}} return;# default
	if {[file isfile $v] &&
	    [file readable $v]} return
	Bad "Expected boolean, but got \"$new\""
    } path/to/readable/file
} ::kettle::ovalidate}

proc ::kettle::ovalidate::Bad {msg} {
    return -code error -errorcode {KETTLE OPTION VETO} $msg
}

# # ## ### ##### ######## ############# #####################
return
