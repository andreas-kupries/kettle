# -*- tcl -*- Copyright (c) 2013 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Core cli setup.

## Based on Cmdr https://core.tcl.tk/akupries/cmdr
## Build dependency circle resolved by having a local copy of the framework
##
## Build dependency circle on the supporting packages "linenoise" and
## "linenoise::facade" (both used by Cmdr) resolved by supplying fake
## packages and commands, and disabling the features of Cmdr using
## their functionality (interactive prompts).

# # ## ### ##### ######## ############# #####################
## Handle import of linenoise(::facade) and the possiblity of them
## missing.

# Standard hook to run after cmdr is loaded. By default, nothing.
namespace eval ::kettle {}
proc ::kettle::PostCmdrHook {} {}

try {
    package require linenoise::facade
    # Implicitly loads "linenoise" as well.
} on error {e o} {
    # linenoise(::facade) is missing.

    # Provide fake packages. Note, breaking the commands across lines
    # like below prevents kettle's scanner from picking these fakes up
    # as exportable packages.
    package provide \
	linenoise         1
    package provide \
	linenoise::facade 1

    # Provide fake functionality (fixed terminal width).
    # This part is used by the Cmdr help, and cannot be disabled.
    # Luckily it can be emulated.
    namespace eval linenoise {
	namespace export columns
    }
    proc ::linenoise::columns {} { return 80 }

    # Overwrite the hook, so that it globally disables all interactive
    # parts of Cmdr. This prevents it from actually using the
    # functionality of the missing packages.
    proc ::kettle::PostCmdrHook {} {
	cmdr interactive 0
    }
}



# # ## ### ##### ######## ############# #####################
## Import Cmdr, the generic command line processing framework.
## Try to use whatever the installation supplies first.
## On failure fall back to the local copy of the framework.
## Modify its behaviour depending on the (non)presence of
## the supporting linenoise(::facade) packages.

# # ## ### ##### ######## ############# #####################
## During development and for debugging force the system to use the
## local copy of the framework. Enables local fixing of bugs before
## transfering the changes to the official sources.  Ditto for cmdr
## extensions we may want or need.

if 1 {apply {dir {
    source [file join $dir util.tcl]
    source [file join $dir vcommon.tcl]
    source [file join $dir validate.tcl]
    source [file join $dir help.tcl]
    #source [file join $dir help_json.tcl]
    #source [file join $dir help_sql.tcl]
    source [file join $dir parameter.tcl]
    source [file join $dir config.tcl]
    source [file join $dir actor.tcl]
    source [file join $dir private.tcl]
    source [file join $dir officer.tcl]
    source [file join $dir cmdr.tcl]
}} [kettle option get @kettledir]/support}

# # ## ### ##### ######## ############# #####################

try {
    package require cmdr
    #kettle io trace {outside cmdr = [package ifneeded cmdr [package present cmdr]]}

} on error {e o} {
    lappend auto_path [kettle option get @kettledir]/support
    package require cmdr
    #kettle io trace {fallback cmdr = [package ifneeded cmdr [package present cmdr]]}
}

# Run the hook delivering linenoise presence information.
::kettle::PostCmdrHook

# # ## ### ##### ######## ############# #####################
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
