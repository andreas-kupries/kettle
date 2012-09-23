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

    set pdir [string map {:: _} $pn]

    set ihelp "
	?lib-directory?
	Install package $pn $pv in the lib/ directory.
    "
    set icmd [list apply {{dst files pn pv} {
	puts "Installing into:       $dst ..."

	set files [lassign $files primary]

	file delete -force ${dst}-new
	file mkdir         ${dst}-new

	file copy $primary {*}$files ${dst}-new

	set c [open ${dst}-new/pkgIndex.tcl w]
	puts $c "package ifneeded [list $pn] $pv \[list source \[file join \$dir [file tail $primary]]]"
	close $c

	catch { file rename -force $dst ${dst}-old }
	file rename -force ${dst}-new $dst
	file delete -force ${dst}-old

	puts -nonewline "Installed package:     "
	kettle gui tag note ; puts $dst
	return
    }} [kettle util libdir]/$pdir$pv $files $pn $pv]

    set dhelp "
	?lib-directory?
	Remove package $pn $pv from the lib/ directory.
    "
    set dcmd [list apply {{dst} {
	file delete -force $dst

	puts -nonewline "Removed package:     "
	kettle gui tag note ; puts $dst
	return
    }} [kettle util libdir]/$pdir$pv]

    foreach suffix {
	{}
	-package
	-tcl-package
    } {
	## Recipe: General Tcl package installation.
	kettle::Def install$suffix $ihelp $icmd
	kettle::Def drop$suffix    $dhelp $dcmd
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::tcl 0
return

# # ## ### ##### ######## ############# #####################
