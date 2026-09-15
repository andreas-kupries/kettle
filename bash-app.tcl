# -*- tcl -*- Copyright (c) 2012-2026 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle shell-based applications

namespace eval ::kettle { namespace export shapp }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::bash-app {fname} {
    ## Recipe: Shell script installation.

    io trace {}
    io trace {DECLARE bash script $fname @ [path sourcedir]}

    set src [path sourcedir $fname]

    if {![file exists $src]} {
	io trace {    NOT FOUND}
	return
    }

    # Derive application name from the path. Ignore extension and the
    # directory the app file is in.
    set name [file tail [file rootname $fname]]

    io trace {	  Accepted: $fname}

    recipe define install-app-$fname "Install application $fname" {name src} {
	path install-script \
	    $src [path bindir] [auto_execok bash]
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

    recipe parent install-app-$fname	   install-bash-applications
    recipe parent install-bash-applications install-applications
    recipe parent install-applications	   install

    recipe parent uninstall-app-$fname	     uninstall-bash-applications
    recipe parent uninstall-bash-applications uninstall-applications
    recipe parent uninstall-applications     uninstall

    recipe parent reinstall-app-$fname	     reinstall-bash-applications
    recipe parent reinstall-bash-applications reinstall-applications
    recipe parent reinstall-applications     reinstall

    recipe define content-app-$fname "Show found application $fname" {name} {
	puts ""
	puts "* app - $name"
    } $name

    recipe parent content-app-$fname content-app
    recipe parent content-app	     content
    return
}

# # ## ### ##### ######## ############# #####################
return
