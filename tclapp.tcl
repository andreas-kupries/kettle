## tclapp.tcl --
# # ## ### ##### ######## ############# #####################
#
#	'kettle tclapp' declaration.
#
# Copyright (c) 2012 Andreas Kupries

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require kettle ; # core
package require kettle::util

# # ## ### ##### ######## ############# #####################
## State, Initialization

namespace eval ::kettle {}

# # ## ### ##### ######## ############# #####################
## 

proc ::kettle::tclapp {fname} {
    ## Recipe: Pure Tcl application installation.

    log {}
    log {DECLARE tcl application $fname @ [sources]}

    set src [kettle sources $fname]

    if {![file exists $src]} {
	log {    NOT FOUND}
	return
    }

    log {    Accepted: $fname}

    kettle::Def install-app-$fname "Install application $fname" \
	[list apply {{src} {
	    util install-script \
		$src [bindir] \
		[info nameofexecutable]
	} ::kettle} $src]

    kettle::Def drop-app-$fname "Uninstall application $fname" \
	[list apply {{src} {
	    util uninstall-application \
		$src [bindir]
	} ::kettle} $src]

    # Hook the application specific recipes into a hierarchy of more
    # general recipes.

    kettle::SetParent install-app-$fname       install-tcl-applications
    kettle::SetParent install-tcl-applications install-applications
    kettle::SetParent install-applications     install

    kettle::SetParent drop-app-$fname       drop-tcl-applications
    kettle::SetParent drop-tcl-applications drop-applications
    kettle::SetParent drop-applications     drop
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::tclapp 0
return

# # ## ### ##### ######## ############# #####################
