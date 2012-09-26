## doc.tcl --
# # ## ### ##### ######## ############# #####################
#
#	'kettle doc' command
#
# Copyright (c) 2012 Andreas Kupries

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require kettle ; # core
package require kettle::util

namespace eval ::kettle::figures {}

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::figures {{figsrcdir doc}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::figures args {}

    set nfigsrcdir [norm $figsrcdir]
    set n [llength [file split $nfigsrcdir]]

    log {}
    log {SCAN tklib/dia figures @ $figsrcdir/}

    # Heuristic search for figures
    set figures {}
    util foreach-file $nfigsrcdir path {
	if {![util diafile $path]} continue

	set path [file join {*}[lrange [file split $path] $n end]]

	log {    Accepted: $figsrcdir/$path}

	lappend figures $path
    }

    if {![llength $figures]} return
    figures::Setup $nfigsrcdir $figures
    return
}

proc ::kettle::figures::Setup {figsrcdir figures} {

    kettle::Def figures {
	(Re)generate the documentation figures.
    } [list apply {{figsrcdir figures} {
	puts "Generating (tklib) diagrams..."

	set here [pwd]

	cd $figsrcdir
	exec 2>@ stderr >@ stdout dia convert -t -o . png {*}$figures

	cd $here
    } ::kettle} $figsrcdir $figures]

    kettle::Def show-figures {
	Show the documentation figures in a Tk GUI
    } [list apply {{figsrcdir figures} {
	puts "Generating (tklib) diagrams..."

	set here [pwd]

	cd $figsrcdir
	exec 2>@ stderr >@ stdout dia show -t {*}$figures

	cd $here
    } ::kettle} $figsrcdir $figures]

    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::figures 0
return

# # ## ### ##### ######## ############# #####################
