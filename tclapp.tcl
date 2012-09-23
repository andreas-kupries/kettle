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
namespace eval ::kettle {}

# # ## ### ##### ######## ############# #####################
## State, Initialization

namespace eval ::kettle {}

# # ## ### ##### ######## ############# #####################
## 

proc ::kettle::tclapp {fname} {
    ## Recipe: Pure Tcl application installation.
    kettle::Def install "
	?lib-directory?
	Install application $fname in the bin/ directory derived from the library directory.
    " [list apply {{src dstdir} {
	set fname [file tail $src]
	set dst   $dstdir/$fname

	### TODO ### Edit hash bang of application to use the installing tclsh

	puts "Installing into:       $dstdir ..."
	file mkdir $dstdir
	file copy -force $src $dst
	puts "Installed application: $dstdir/$fname"
	return
    }} [kettle path $fname] [kettle bindir]]

    ## Recipe: Pure Tcl application removal.
    kettle::Def drop "
	?lib-directory?
	Remove application $fname from the bin/ directory derived from the library directory.
    " [list apply {{dst} {
	file delete -force $dst
	puts "Removed application: $dst"
	return
    }} [kettle bindir]/$fname]

    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::tclapp 0
return

# # ## ### ##### ######## ############# #####################
