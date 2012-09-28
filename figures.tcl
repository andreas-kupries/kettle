# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle tklib/diagram figures (documentation)

namespace eval ::kettle { namespace export figures }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::figures {{figsrcdir doc/figures}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::figures args {}

    set root [path sourcedir $figsrcdir]

    io trace {}
    io trace {SCAN tklib/dia figures @ $figsrcdir/}

    # Heuristic search for figures

    set figures {}
    path foreach-file $root path {
	set spath [path strip $path $root]

	if {[catch {
	    path diagram-file $path
	} adia]} {
	    io err { io puts stderr "    Skipped: $figsrcdir/$spath @ $adia" }
	    continue
	}
	if {!$adia} continue

	io trace {    Accepted: $figsrcdir/$spath}

	lappend figures $spath
    }

    if {![llength $figures]} return

    # Put the figures into recipes.

    recipe define figures {
	(Re)generate the documentation figures.
    } {figsrcdir figures} {

	io puts "Generating (tklib) diagrams..."

	set here [pwd]

	# TODO # support code to pipe, or capture output for display.
	cd $figsrcdir
	exec 2>@ stderr >@ stdout dia convert -t -o . png {*}$figures

	cd $here

    } $figsrcdir $figures

    recipe define show-figures {
	Show the documentation figures in a Tk GUI
    } {figsrcdir figures} {
	io puts "Generating (tklib) diagrams..."

	set here [pwd]

	cd $figsrcdir
	exec 2>@ stderr >@ stdout dia show -t {*}$figures

	cd $here
    } $figsrcdir $figures

    return
}

# # ## ### ##### ######## ############# #####################
return
