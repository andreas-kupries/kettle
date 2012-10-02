# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Manage tool requirements

# # ## ### ##### ######## ############# #####################
## Export (internals)

namespace eval ::kettle::tool {
    namespace export {[a-z]*}
    namespace ensemble create

    namespace import ::kettle::io
    namespace import ::kettle::option
}

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::tool::declare {names {validator {}}} {
    set primary [lindex $names 0]
    option define --with-$primary {} {}

    foreach name $names {
	set cmd [auto_execok $name]
	option setd --with-$primary $cmd

	# Do not try to validate applications which were not found.
	if {![llength $cmd]} continue
	if {$validator eq ""} break
	if {[apply [list {cmd} $validator] $cmd]} break

	option setd --with-$primary {}
    }
    return
}

proc ::kettle::tool::get {name} {
    set cmd [option get --with-$name]
    if {![llength $cmd]} {
	io err {
	    io puts "Tool $name required, but not found in PATH"
	    io puts "Please specify its location through option --with-$name"
	}
    }
    return $cmd
}

# # ## ### ##### ######## ############# #####################
return

