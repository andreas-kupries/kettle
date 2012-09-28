# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Application Core

namespace eval ::kettle {}

# # ## ### ##### ######## ############# #####################
## API commands.

proc ::kettle::Application {} {
    global argv

    # Process arguments: -f, -v, --* options, and goals

    if {[lindex $argv 0] eq {-f}} {
	set argv [lassign $argv __ path]
	set declfile [path norm $path]

    } elseif {[file exists build.tcl]} {
	set declfile [path norm build.tcl]

    } else {
	io err { io puts "Build declaration file neither specified, nor found" }
	::exit 1
    }

    if {[lindex $argv 0] eq {-v}} {
	set argv [lrange $argv 1 end]
	io trace-on
    }

    set goals {}
    while {[llength $argv]} {
	set o [lindex $argv 0]
	switch -glob -- $o {
	    --* {
		option set $o [lindex $argv 1]
		set argv [lrange $argv 2 end]
	    }
	    default {
		lappend goals $o
		option set @goals $goals
		set argv [lrange $argv 1 end]
	    }
	}
    }

    # Process the user's build declarations for the sources (-f)

    option set @srcdir [file dirname $declfile]

    if {[catch {
	::source $declfile
    }]} {
	# Report troubles in the declarations and abort.
	io err { io puts $::errorInfo }
	::exit 1
    }

    # And execute the chosen goals

    recipe run {*}[option get @goals]
    ::exit 0
    return
}

# # ## ### ##### ######## ############# #####################
return
