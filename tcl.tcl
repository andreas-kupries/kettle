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

    set packages {}
    kettle util foreach-file [kettle sources] path {
	if {[catch {
	    lassign [kettle util provides $path] pn pv
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
    kettle::log {	Tcl Package Setup $pn $pv ... $files}

    set pdir [string map {:: _} $pn]
    set dst  [kettle libdir]/$pdir$pv

    kettle::Def install-pkg-$pn "Install package $pn $pv" \
	[list apply {{dst files pn pv} {
	    set tmpfile [pid].pkgIndex

	    set primary [lindex $files 0]
	    set c [open $tmpfile w]
	    puts $c "package ifneeded [list $pn] $pv \[list source \[file join \$dir [file tail $primary]]]"
	    close $c

	    kettle util install_group \
		"Installing package $dst" \
		$dst {*}$files $tmpfile
	    file delete $tmpfile
	    return
	}} $dst $files $pn $pv]

    kettle::Def drop-pkg-$pn "Remove package $pn $pv" \
	[list apply {{dst} {
	    kettle util drop_path \
		"Remove package $dst" \
		$dst
	}} $dst]

    # Hook the package specific recipes into a hierarchy of more
    # general recipes.

    kettle::SetParent install-pkg-$pn      install-tcl-packages
    kettle::SetParent install-tcl-packages install-packages
    kettle::SetParent install-packages     install

    kettle::SetParent drop-pkg-$pn      drop-tcl-packages
    kettle::SetParent drop-tcl-packages drop-packages
    kettle::SetParent drop-packages     drop
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::tcl 0
return

# # ## ### ##### ######## ############# #####################
