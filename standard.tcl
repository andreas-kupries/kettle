# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Standard recipes.
## - null    - no operation.
## - recipes - recipe list
## - help    - recipe help
## - gui     - standard GUI to recipes.

# # ## ### ##### ######## ############# #####################

kettle cli extend null {
    section Targets Standard
    description {
	No operation.
	Debugging helper (use with -trace).
    }
} [lambda {config} {}]

kettle cli learn {
    alias nop = null
}

kettle cli extend forever {
    section Targets Standard
    description {
	Infinite loop.
	Debugging helper (use with -trace).
    }
} [lambda {config} { vwait forever }]

# # ## ### ##### ######## ############# #####################

kettle cli extend {show state} {
    section Targets Standard
    description {
	Show the state of internal kettle variables controlling
	its behaviour, like relevant directories, paths to tools,
	etc.
    }
} [lambda@ ::kettle {config} {
    set names [lsort -dict [option names @*]]
    io puts {}
    foreach name $names padded [strutil padr $names] {
	set value [option get $name]
	if {[string match *\n* $value]} {
	    set value \n[strutil reflow $value "\t    "]
	}
        io puts "\t$padded = $value"
    }
}]

# # ## ### ##### ######## ############# #####################

kettle recipe define meta-status {
    Status of meta data for Tcl packages and applications.
} {} {
    meta show-status
}

# # ## ### ##### ######## ############# #####################

kettle recipe define gui {
    Graphical interface to the system.
} {} {
    gui make
}

# # ## ### ##### ######## ############# #####################
## Anchors for project-based recipes to hook into.

kettle recipe anchor validate {
    Validate the entire project.
}

kettle recipe anchor doc {
    Manage the project documentation.
} !all

kettle recipe anchor {doc install} {
    Install the project documentation.
}

kettle recipe anchor {doc uninstall} {
    Uninstall the project documentation.
}

kettle recipe anchor {doc reinstall} {
    Reinstall the project documentation.
}

# # ## ### ##### ######## ############# #####################

kettle recipe anchor install {
    Install the project.
}
kettle recipe anchor {install doc} {
    Install the project documentation.
}

# # ## ### ##### ######## ############# #####################

kettle recipe anchor uninstall {
    Uninstall the project.
}
kettle recipe anchor {uninstall doc} {
    Uninstall the project documentation.
}

# # ## ### ##### ######## ############# #####################

kettle recipe anchor reinstall {
    Reinstall the project. I.e. uninstall it, then install it again.
}
kettle recipe anchor {reinstall doc} {
    Reinstall the project documentation.
}

# # ## ### ##### ######## ############# #####################
return
