## tcl.tcl --
# # ## ### ##### ######## ############# #####################
#
#	'kettle tcl' command
#
# Copyright (c) 2012 Andreas Kupries

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require  kettle ; # core
package require  kettle::util

# # ## ### ##### ######## ############# #####################
## State, Initialization

namespace eval ::kettle::tcl {}

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::tcl {} {
    # Auto-search for packages to install, collect names, versions, and files.
    # Auto-search for documentation, testsuites, benchmarks.

    doc
    #testsuites
    #benchmarks

    set packages {}
    kettle util foreach-file [sources] path {
	if {[catch {
	    lassign [util provides $path] pn pv
	}]} continue
	lappend packages $path $pn $pv
    }

    foreach {primary pn pv} $packages {
	set     files {}
	lappend files $primary

	# TODO: Look for files referenced by the primary.
	tcl::Setup $files $pn $pv
    }
    return
}

proc ::kettle::tcl::Setup {files pn pv} {
    kettle log {	Tcl Package Setup $pn $pv ... $files}

    set pkgdir [kettle libdir]/[string map {:: _} $pn]$pv

    kettle::Def install-package-$pn "Install package $pn $pv" \
	[list apply {{pkgdir files pn pv} {

	    set tmpdir [util tmpfile]
	    file mkdir $tmpdir
	    set tmpfile $tmpdir/pkgIndex.tcl

	    set primary [lindex $files 0]
	    util write $tmpfile \
		"package ifneeded [list $pn] $pv \[list source \[file join \$dir [file tail $primary]]]"

	    util install-file-group \
		"package $pn $pv" \
		$pkgdir {*}$files $tmpfile

	    file delete $tmpfile
	    file delete $tmpdir
	    return
	} ::kettle} $pkgdir $files $pn $pv]

    kettle::Def drop-package-$pn "Uninstall package $pn $pv" \
	[list apply {{pkgdir pn pv} {
	    util uninstall-file-group \
		"package $pn $pv" \
		$pkgdir
	} ::kettle} $pkgdir $pn $pv]

    # Hook the package specific recipes into a hierarchy of more
    # general recipes.

    kettle::SetParent install-package-$pn  install-tcl-packages
    kettle::SetParent install-tcl-packages install-packages
    kettle::SetParent install-packages     install

    kettle::SetParent drop-package-$pn  drop-tcl-packages
    kettle::SetParent drop-tcl-packages drop-packages
    kettle::SetParent drop-packages     drop
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::tcl 0
return

# # ## ### ##### ######## ############# #####################
