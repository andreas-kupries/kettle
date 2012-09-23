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

    set ihelp "
	?lib-directory?
	Install application $fname in the bin/ directory.
    "
    set icmd [list apply {{src dstdir} {
	set fname [file tail $src]
	set dst   $dstdir/$fname

	puts "Installing into:       $dstdir ..."
	file mkdir $dstdir
	file copy -force $src $dst
	kettle util fixhashbang $dst [info nameofexecutable]
	kettle util set-executable $dst

	puts -nonewline "Installed application: "
	kettle gui tag note ; puts $dst
	return
    }} [kettle sources $fname] [kettle util bindir]]

    set dhelp "
	?lib-directory?
	Remove application $fname from the bin/ directory.
    "
    set dcmd [list apply {{dst} {
	file delete -force $dst

	puts -nonewline "Removed application: "
	kettle gui tag note ; puts $dst
	return
    }} [kettle util bindir]/$fname]

    foreach suffix {
	{}
	-application
	-tcl-application
    } {
	kettle::Def install$suffix $ihelp $icmd
	kettle::Def drop$suffix    $dhelp $dcmd
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::tclapp 0
return

# # ## ### ##### ######## ############# #####################
