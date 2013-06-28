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

    meta scan

    set src [path sourcedir $fname]

    if {![file exists $src]} {
	io trace {    NOT FOUND}
	return
    }

    set name [file rootname $fname]
    meta read-internal $src application $name

    io trace {    Accepted: $fname}

    recipe define install-app-$fname "Install application $fname" {name src} {
	path install-script \
	    $src [path bindir] [info nameofexecutable] \
	    [lambda {name dst} {
		kettle meta insert $dst application $name
	    } $name]
    } $name $src

    recipe define uninstall-app-$fname "Uninstall application $fname" {src} {
	path uninstall-application \
	    $src [path bindir]
    } $src

    recipe define reinstall-app-$fname "Reinstall application $fname" {fname} {
	invoke self uninstall-app-$fname
	invoke self install-app-$fname
    } $fname

    # Hook the application specific recipes into a hierarchy of more
    # general recipes.

    recipe parent install-app-$fname       install-tcl-applications
    recipe parent install-tcl-applications install-applications
    recipe parent install-applications     install

    recipe parent uninstall-app-$fname       uninstall-tcl-applications
    recipe parent uninstall-tcl-applications uninstall-applications
    recipe parent uninstall-applications     uninstall

    recipe parent reinstall-app-$fname       reinstall-tcl-applications
    recipe parent reinstall-tcl-applications reinstall-applications
    recipe parent reinstall-applications     reinstall
    return
}

# # ## ### ##### ######## ############# #####################
return
