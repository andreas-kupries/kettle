# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle tklib/diagram figures (documentation)

namespace eval ::kettle { namespace export figures }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::figures {{figsrcdir doc/figures}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::figures args {}

    # Heuristic search for documentation files.
    # Aborts caller when nothing is found.
   lassign [path scan \
		tklib/diagram \
		$figsrcdir \
		{path diagram-file}] \
	root figures

    # Put the figures into recipes.

    recipe define figures {
	(Re)generate the documentation figures.
    } {figsrcdir figures} {
	path in $figsrcdir {
	    io puts "Generating (tklib) diagrams..."
	    path exec dia convert -t -o . png {*}$figures
	}
    } $root $figures

    recipe define show-figures {
	Show the documentation figures in a Tk GUI
    } {figsrcdir figures} {
	path in $figsrcdir {
	    io puts "Showing (tklib) diagrams..."
	    path exec dia show -t {*}$figures
	}
    } $root $figures

    return
}

# # ## ### ##### ######## ############# #####################
return
