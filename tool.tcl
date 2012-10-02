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

proc ::kettle::tool::declare {name} {
    option define --with-$name {} {}
    option setd   --with-$name [auto_execok $name]
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

