## tclapp.tcl --
# # ## ### ##### ######## ############# #####################
#
#	'kettle tclapp' declaration.
#
# Copyright (c) 2012 Andreas Kupries

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require  kettle ; # core
package require  kettle::util

# # ## ### ##### ######## ############# #####################
## State, Initialization

namespace eval ::kettle {}

# # ## ### ##### ######## ############# #####################
## 

proc ::kettle::tclapp {fname} {
    ## Recipe: Pure Tcl application installation.

    set src [kettle sources $fname]
    set dst [kettle util bindir]/$fname

    kettle::Def install-$fname "
	?lib-directory?
	Install application $fname in the bin/ directory.
    " [list apply {{fname src dst} {
	kettle util install_path \
	    "Installing application $src" \
	    $src $dst {
		kettle util fixhashbang    ${dst}-new [info nameofexecutable]
		kettle util set-executable ${dst}-new
	    }
    }} $fname $src $dst]

    kettle::Def drop-$fname "
	?lib-directory?
	Remove application $fname from the bin/ directory.
    " [list apply {{dst} {
	kettle util drop_path \
	    "Remove application $dst" \
	    $dst
    }} $dst]

    # Hook the application specific recipes into a hierarchy of more
    # general recipes.

    kettle::DefHook install-$fname           install-tcl-applications
    kettle::DefHook install-tcl-applications install-applications
    kettle::DefHook install-applications     install

    kettle::DefHook drop-$fname           drop-tcl-applications
    kettle::DefHook drop-tcl-applications drop-applications
    kettle::DefHook drop-applications     drop
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::tclapp 0
return

# # ## ### ##### ######## ############# #####################
