# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Support for the standard gui recipe.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::gui {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## State

namespace eval ::kettle::gui {
    variable INSTALLPATH {}
    variable buttons     {}

    namespace import ::kettle::io
    namespace import ::kettle::option
    namespace import ::kettle::recipe
}

# # ## ### ##### ######## ############# #####################

proc ::kettle::gui::make {} {
    variable buttons
    variable INSTALLPATH

    # Dynamic adaptation to the config database contents, and
    # ability to extend that database from the GUI.
    # ==> ttk notebook, tree.

    package require Tk
    package require widget::scrolledwindow ; # Tklib

    label  .l -text {Install Path: }
    entry  .e -textvariable ::kettle::gui::INSTALLPATH

    set rr 0
    foreach r [lsort -dict [recipe names]] {
	# ignore some of the standard recipes, match
	if {$r in {gui recipes}} continue

	lappend buttons [button .i$rr \
			     -command [list ::kettle::gui::Run $r] \
			     -text $r -anchor w]
	grid   .i$rr -row $rr -column 2 -sticky new
	grid rowconfigure . $rr -weight 0
	incr rr
    }

    lappend buttons [button .q -command ::_exit -text Exit -anchor w]
    grid   .q -row $rr -column 2 -sticky new

    widget::scrolledwindow .st -borderwidth 1 -relief sunken
    text .t
    .st setwidget .t

    grid .l  -row 0 -column 0 -sticky new
    grid .e  -row 0 -column 1 -sticky new
    grid .st -row 1 -column 0 -sticky swen -columnspan 2 -rowspan $rr

    grid rowconfigure    . $rr -weight 1

    grid columnconfigure . 0 -weight 0
    grid columnconfigure . 1 -weight 1
    grid columnconfigure . 2 -weight 0

    set INSTALLPATH [info library]

    # Disable uncontrolled exit. This may come out of deeper layers,
    # like, for example, critcl compilation.

    rename ::exit   ::_exit
    proc   ::exit {{status 0}} {
	apply {{} {
	    io ok { io puts DONE }
	} ::kettle}
	return
    }

    wm protocol . WM_DELETE_WINDOW ::_exit

    io setwidget .t

    # And start to interact with the user.
    vwait forever
    return

}

# # ## ### ##### ######## ############# #####################
## Internal help.

proc ::kettle::gui::Run {goal} {
    variable INSTALLPATH

    #set argv [list $INSTALLPATH]
    #=> update option database

    State disabled

    .t delete 0.1 end

    option set --lib-dir $INSTALLPATH
    recipe run $goal

    State normal
    return
}

proc ::kettle::gui::State {e} {
    variable buttons
    foreach b $buttons {
	$b configure -state $e
    }
    return
}

# # ## ### ##### ######## ############# #####################
return
