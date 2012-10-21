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
    variable actions     {}

    namespace import ::kettle::io
    namespace import ::kettle::option
    namespace import ::kettle::recipe
    namespace import ::kettle::status
}

# # ## ### ##### ######## ############# #####################

proc ::kettle::gui::make {} {
    package require Tk

    ttk::notebook .n
    ttk::frame  .options
    ttk::frame  .actions
    ttk::button .exit -command ::_exit -text Exit

    .n add .options -text Configuration -underline 0
    .n add .actions -text Action        -underline 0

    pack .n    -side top   -expand 1 -fill both
    pack .exit -side right -expand 0 -fill both

    Options     .options
    Actions     .actions

    .n select 1


    #AddAction $win ::_exit Exit 1

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

    # And start to interact with the user.
    vwait forever
    return
}

proc ::kettle::gui::Options {win} {
    variable INSTALLPATH

    set top $win ; if {$top eq {}} { set top . }

    # Dynamic adaptation to the config database contents, and
    # ability to extend that database from the GUI.
    # ==> ttk notebook, tree.

    label ${win}.l -text {Install Path: }
    entry ${win}.e -textvariable ::kettle::gui::INSTALLPATH

    grid ${win}.l  -row 0 -column 0 -sticky new
    grid ${win}.e  -row 0 -column 1 -sticky new

    grid columnconfigure $top 0 -weight 0
    grid columnconfigure $top 1 -weight 1

    set INSTALLPATH [info library]
}

proc ::kettle::gui::Actions {win} {
    set top $win ; if {$top eq {}} { set top . }

    package require widget::scrolledwindow ; # Tklib

    # TODO: Extend recipe definitions to carry this information.
    set special {help help-recipes help-options show show-configuration show-state}
    set ignore  {gui null list list-recipes list-options}

    foreach r $special {
	# treat a few recipes out of order to have them at the top.
	AddActionForRecipe $win $r
    }
    foreach r [lsort -dict [recipe names]] {
	# ignore the standard recipes which are nonsensical for the
	# gui, and those which we treated out of order (see above).
	if {($r in $ignore) || ($r in $special)} continue
	AddActionForRecipe $win $r
    }

    widget::scrolledwindow ${win}.st -borderwidth 1 -relief sunken
    text                   ${win}.t

    ${win}.st setwidget ${win}.t

    grid ${win}.st -row 0 -column 0 -sticky swen \
	-columnspan 2 -rowspan [NumActions]

    grid columnconfigure $top 2 -weight 0

    io setwidget ${win}.t
    return
}

# # ## ### ##### ######## ############# #####################
## Internal help.

proc ::kettle::gui::NumActions {} {
    variable actions
    llength $actions
}

proc ::kettle::gui::AddActionForRecipe {win r} {
    AddAction $win [list ::kettle::gui::Run $win $r] [Label $r] 0
}

proc ::kettle::gui::AddAction {win cmd label weight} {
    variable actions
    set row [llength $actions]

    set top $win ; if {$top eq {}} { set top . }

    # ttk::button -> no -anchor option, labels centered.
    button ${win}.i$row -command $cmd -text $label -anchor w
    grid   ${win}.i$row -row $row -column 2 -sticky new
    grid rowconfigure $top $row -weight $weight

    lappend actions ${win}.i$row
    return
}

proc ::kettle::gui::Label {recipe} {
    set result {}
    foreach e [split $recipe -] {
	lappend result [string totitle $e]
    }
    return [join $result { }]
}

proc ::kettle::gui::Run {win recipe} {
    variable INSTALLPATH

    #set argv [list $INSTALLPATH]
    #=> update option database

    Action disabled

    ${win}.t delete 0.1 end

    option set --lib-dir $INSTALLPATH
    recipe run $recipe

    status clear
    Action normal
    return
}

proc ::kettle::gui::Action {e} {
    variable actions
    foreach b $actions {
	$b configure -state $e
    }
    return
}

# # ## ### ##### ######## ############# #####################
return
