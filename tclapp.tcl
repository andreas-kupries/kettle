# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle tklib/diagram figures (documentation)

namespace eval ::kettle { namespace export tclapp }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::tclapp {fname} {
    ## Recipe: Pure Tcl application installation.

    io trace {}
    io trace {DECLARE tcl application $fname @ [path sourcedir]}

    set src [path sourcedir $fname]

    if {![file exists $src]} {
	io trace {    NOT FOUND}
	return
    }

    io trace {    Accepted: $fname}

    recipe define install-app-$fname "Install application $fname" {src} {
	path install-script \
	    $src [path bindir] \
	    [info nameofexecutable]
    } $src

    recipe define uninstall-app-$fname "Uninstall application $fname" {src} {
	path uninstall-application \
	    $src [path bindir]
    } $src

    # Hook the application specific recipes into a hierarchy of more
    # general recipes.

    recipe parent install-app-$fname       install-tcl-applications
    recipe parent install-tcl-applications install-applications
    recipe parent install-applications     install

    recipe parent uninstall-app-$fname       uninstall-tcl-applications
    recipe parent uninstall-tcl-applications uninstall-applications
    recipe parent uninstall-applications     uninstall
    return
}

# # ## ### ##### ######## ############# #####################
return
