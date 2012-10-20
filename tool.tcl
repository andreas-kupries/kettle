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
    option define      --with-$primary {} rfile
    option no-work-key --with-$primary

    foreach name $names {
	set cmd [auto_execok $name]
	option set-default --with-$primary $cmd

	# Do not try to validate applications which were not found.
	# Continue search.
	if {![llength $cmd]} continue

	# Do not try to validate if we have no validation code.
	# Assume ok, stop search.
	if {$validator eq ""} break

	# Validate. If ok, stop search.
	if {[apply [list {cmd} $validator] $cmd]} break

	# Validation failed, revert, continue search.
	option set-default --with-$primary {}
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

