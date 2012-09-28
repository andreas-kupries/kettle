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
    puts [lsort -dict [recipe names]]
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
