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
    set dst [kettle bindir]/$fname

    kettle::Def install-app-$fname "Install application $fname" \
	[list apply {{fname src dst} {
	    kettle util install_path \
		"Installing application $src" \
		$src $dst {
		    kettle util fixhashbang    ${dst}-new [info nameofexecutable]
		    kettle util set-executable ${dst}-new
		}
	}} $fname $src $dst]

    kettle::Def drop-app-$fname "Remove application $fname" \
	[list apply {{dst} {
	    kettle util drop_path \
		"Remove application $dst" \
		$dst
	}} $dst]

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
