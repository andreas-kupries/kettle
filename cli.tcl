# -*- tcl -*- Copyright (c) 2013 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Core cli setup.

# # ## ### ##### ######## ############# #####################
## Import a generic command line processing framework.
## Try to use whatever the installation supplies first.
## On failure fall back to the local copy of the framework.

try {
    package require cmdr
    #kettle io trace {outside cmdr = [package ifneeded cmdr [package present cmdr]]}

} on error {e o} {
    lappend auto_path [kettle option get @kettledir]/support
    package require cmdr
    #kettle io trace {fallback cmdr = [package ifneeded cmdr [package present cmdr]]}
}

#puts [package ifneeded cmdr [package present cmdr]]
#puts [package ifneeded cmdr::config [package present cmdr::config]]
#puts [package ifneeded cmdr::officer [package present cmdr::officer]]

# # ## ### ##### ######## ############# #####################
## Export: cli instance.

cmdr create kettle::cli kettle {
    description {
	The kettle command line application.
    }
    # Command set is dynamic. See
    # - recipes.tcl
    # - standard.tcl
    # - special.tcl

    # Global option for all: --state ?
    # Might be easier to handle recursion with hidden command
    # handling state, and re-invoking the actual command.
}

# # ## ### ##### ######## ############# #####################
return
