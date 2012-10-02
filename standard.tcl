# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Standard recipes.
## - null    - no operation.
## - recipes - recipe list
## - help    - recipe help
## - gui     - standard GUI to recipes.

# # ## ### ##### ######## ############# #####################

kettle recipe define null {
    No operation. Debugging helper (use with -v).
} {} {}

# # ## ### ##### ######## ############# #####################

kettle recipe define recipes {
    List all available recipes, without details.
} {} {
    io puts [lsort -dict [recipe names]]
}

# # ## ### ##### ######## ############# #####################

kettle recipe define options {
    List all available options, without details.
} {} {
    io puts [lsort -dict [option names]]
}

kettle recipe define show-options {
    Show the state of the option database.
} {} {
    set maxl 0
    set names [lsort -dict [option names]]

    foreach name $names {
        if {[string length $name] > $maxl} {
            set maxl [string length $name]
        }
    }

    set maxl [expr {$maxl + 2}]
    foreach name $names {
        io puts [format "%-*s = %s" $maxl $name [option get $name]]
    }
}

kettle recipe define show-state {
    Show the state
} {} {
    set maxl 0
    set names [lsort -dict [option names @*]]

    foreach name $names {
        if {[string length $name] > $maxl} {
            set maxl [string length $name]
        }
    }

    set maxl [expr {$maxl + 2}]
    foreach name $names {
        io puts [format "%-*s = %s" $maxl $name [option get $name]]
    }
}

# # ## ### ##### ######## ############# #####################

kettle recipe define help {
    Print the help.
} {} {
    recipe help {Usage: }
}

# # ## ### ##### ######## ############# #####################

kettle recipe define gui {
    Graphical interface to the system.
} {} {
    gui make
}

# # ## ### ##### ######## ############# #####################
return
