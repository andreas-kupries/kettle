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

# TODO: Make it a proper alias of 'null' above.
kettle cli extend nop {
    #section Targets Standard
    section Targets Standard
    description {
	No operation.
	Debugging helper (use with -trace).
    }
} [lambda {config} {}]

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

kettle recipe anchor validate {
    Validation of various parts of the project.
}

# # ## ### ##### ######## ############# #####################
return
