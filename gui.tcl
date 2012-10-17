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
    variable INSTALLPATH

    # Dynamic adaptation to the config database contents, and
    # ability to extend that database from the GUI.
    # ==> ttk notebook, tree.

    package require Tk
    package require widget::scrolledwindow ; # Tklib

    label  .l -text {Install Path: }
    entry  .e -textvariable ::kettle::gui::INSTALLPATH

    foreach r {help show-options show-state} {
	# treat a few recipes out of order to have them at the top.
	MakeGoalButton $r
    }
    foreach r [lsort -dict [recipe names]] {
	# ignore the standard recipes which are nonsensical for the
	# gui, and those which we treated out of order (see above).
	if {$r in {gui null recipes options help show-options show-state}} continue
	MakeGoalButton $r
    }

    MakeButton ::_exit Exit 1

    widget::scrolledwindow .st -borderwidth 1 -relief sunken
    text .t
    .st setwidget .t

    grid .l  -row 0 -column 0 -sticky new
    grid .e  -row 0 -column 1 -sticky new
    grid .st -row 1 -column 0 -sticky swen -columnspan 2 -rowspan [NButtons]

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

proc ::kettle::gui::NButtons {} {
    variable buttons
    llength $buttons
}

proc ::kettle::gui::MakeGoalButton {goal} {
    MakeButton [list ::kettle::gui::Run $goal] [Label $goal] 0
}

proc ::kettle::gui::MakeButton {cmd label weight} {
    variable buttons
    set row [llength $buttons]

    # ttk::button -> no -anchor option, labels centered.
    button .i$row -command $cmd -text $label -anchor w
    grid .i$row -row $row -column 2 -sticky new
    grid rowconfigure . $row -weight $weight

    lappend buttons .i$row
    return
}

proc ::kettle::gui::Label {goal} {
    set r {}
    foreach e [split $goal -] {
	lappend r [string totitle $e]
    }
    return [join $r { }]
}

proc ::kettle::gui::Run {goal} {
    variable INSTALLPATH

    #set argv [list $INSTALLPATH]
    #=> update option database

    State disabled

    .t delete 0.1 end

    option set --lib-dir $INSTALLPATH
    recipe run $goal

    # TODO: Clear work database. Allow multiple uses of each recipe.

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
