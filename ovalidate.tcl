# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Option handling, sub layer: Types & Validation.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::ovalidate {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

proc ::kettle::ovalidate::Def {name script guiscript {label {}}} {
    if {$label eq {}} { set label $name }

    namespace eval ::kettle::ovalidate::${name} {
	namespace export help check gui
	namespace ensemble create
    }
    proc ::kettle::ovalidate::${name}::check {v} $script
    proc ::kettle::ovalidate::${name}::help  {} [list return $label]
    proc ::kettle::ovalidate::${name}::gui   {win option} $guiscript
    return
}

# # ## ### ##### ######## ############# #####################
## API

proc ::kettle::ovalidate::enum {choices cmd args} {
    Enum::${cmd} $choices {*}$args
}

namespace eval ::kettle::ovalidate::Enum {}

proc ::kettle::ovalidate::Enum::check {choices v} {
    if {$v in $choices} return
    set c [linsert '[join $choices {', '}]' end-1 or]
    Bad "Expected one of $c, got \"$v\""
}

proc ::kettle::ovalidate::Enum::help {choices} {
    return [join $choices |]
}

proc ::kettle::ovalidate::Enum::gui {choices win option} {
    ttk::combobox $win -values $choices
    $win insert 0 [kettle option get $option]
    $win configure -state readonly
    bind $win <<ComboboxSelected>> [lambda {win option} {
	kettle option set $option [$win get]
    } $win $option]
}

apply {{} {
    Def any {
	return
    } {
	ttk::entry $win \
	    -validate focusout \
	    -validatecommand [lambda {win option} {
		kettle option set $option [$win get]
		return 1
	    } $win $option]

	$win insert 0 [kettle option get $option]

	kettle option onchange $option {win} {
	    $win delete 0 end
	    $win insert 0 [kettle option get $option]
	} $win
	return
    }

    Def string {
	return
    } {
	ttk::entry $win \
	    -validate focusout \
	    -validatecommand [lambda {win option} {
		kettle option set $option [$win get]
		return 1
	    } $win $option]

	$win insert 0 [kettle option get $option]

	kettle option onchange $option {win} {
	    $win delete 0 end
	    $win insert 0 [kettle option get $option]
	} $win
	return
    }

    Def boolean {
	if {[string is boolean -strict $v]} return
	Bad "Expected boolean, but got \"$new\""
    } {
	ttk::checkbutton $win \
	    -command [lambda {win option} {
	    kettle option set $option [expr {"selected" in [$win state]}]
	} $win $option]

	if {[kettle option get $option]} {
	    $win state selected
	} else {
	    $win state !selected
	}

	kettle option onchange $option {win} {
	    if {[kettle option get $option]} {
		$win state selected
	    } else {
		$win state !selected
	    }
	} $win
	return
    }

    Def int0 {
	if {[string is int -strict $v] && ($v >= 0)} return
	Bad "Expected integer >= 0, but got \"$new\""
    } {
	# TODO option type int0 gui -- ttk::entry with validation, or spinbox
	return
    }

    Def int1 {
	if {[string is int -strict $v] && ($v > 0)} return
	Bad "Expected integer > 0, but got \"$new\""
    } {
	# TODO option type int1 gui -- ttk::entry with validation, or spinbox
	return
    }

    Def int {
	if {[string is int -strict $v]} return
	Bad "Expected integer, but got \"$new\""
    } {
	# TODO option type int gui -- ttk::entry with validation, or spinbox
	return
    }

    Def listsimple {
	if {[string is list -strict $v]} return
	Bad "Expected tcl list, got \"$v\""
    } {
	ttk::button $win -text ... \
	    -command [lambda {win option} {
		package require widget::listsimple
		package require widget::dialog

		set ::$option [kettle option get $option]

		widget::dialog $win.d \
		    -title "Edit $option" \
		    -parent $win \
		    -type okcancel

		widget::listsimple $win.d.l \
		    -listvariable ::$option

		$win.d setwidget $win.d.l
		set btn [$win.d display]

		set v [set ::$option]
		unset ::$option

		if {$btn eq "cancel"} return
		kettle option set $option $v
		return
	    } $win $option]
	return
    }

    Def directory return {
	ttk::frame  $win
	ttk::entry  $win.e \
	    -validate focusout \
	    -validatecommand [lambda {win option} {
		kettle option set $option [$win.e get]
		return 1
	    } $win $option]

	ttk::button $win.b -text ... -command [lambda {win option} {
	    set dir [kettle path norm [$win.e get]]
	    set dir [tk_chooseDirectory \
			 -parent $win \
			 -initialdir $dir \
			 -title "Choose $option"]
	    if {$dir eq {}} return

	    $win.e delete 0 end
	    $win.e insert 0 $dir
	    $win.e validate
	} $win $option]

	pack $win.e -side left  -expand 1 -fill both
	pack $win.b -side right -expand 0 -fill both

	$win.e insert 0 [kettle option get $option]

	kettle option onchange $option {win} {
	    $win.e delete 0 end
	    $win.e insert 0 [kettle option get $option]
	    $win.e validate
	} $win
	return
    }

    Def readable.file {
	if {$v eq {}} return;# default
	if {[file isfile $v] &&
	    [file readable $v]} return
	Bad "Expected boolean, but got \"$new\""
    } {
	ttk::frame  $win
	ttk::entry  $win.e \
	    -validate focusout \
	    -validatecommand [lambda {win option} {
		kettle option set $option [$win.e get]
		return 1
	    } $win $option]

	ttk::button $win.b -text ... -command [lambda {win option} {
	    set path [kettle path norm [$win.e get]]
	    set path [tk_getOpenFile \
			  -parent $win \
			  -multiple 0 \
			  -initialdir [file dirname $path] \
			  -initialfile $path \
			  -title "Choose $option"]
	    if {$path eq {}} return

	    $win.e delete 0 end
	    $win.e insert 0 $path
	    $win.e validate
	} $win $option]

	pack $win.e -side left  -expand 1 -fill both
	pack $win.b -side right -expand 0 -fill both

	$win.e insert 0 [kettle option get $option]

	kettle option onchange $option {win} {
	    $win.e delete 0 end
	    $win.e insert 0 [kettle option get $option]
	    $win.e validate
	} $win
	return
    } path/to/readable/file

    Def path return {
	ttk::frame  $win
	ttk::entry  $win.e \
	    -validate focusout \
	    -validatecommand [lambda {win option} {
		kettle option set $option [$win.e get]
		return 1
	    } $win $option]

	ttk::button $win.b -text ... -command [lambda {win option} {
	    set path [kettle path norm [$win.e get]]
	    set path [tk_getOpenFile \
			  -parent $win \
			  -multiple 0 \
			  -initialdir [file dirname $path] \
			  -initialfile $path \
			  -title "Choose $option"]
	    if {$path eq {}} return

	    $win.e delete 0 end
	    $win.e insert 0 $path
	    $win.e validate
	} $win $option]

	pack $win.e -side left  -expand 1 -fill both
	pack $win.b -side right -expand 0 -fill both

	$win.e insert 0 [kettle option get $option]

	kettle option onchange $option {win} {
	    $win.e delete 0 end
	    $win.e insert 0 [kettle option get $option]
	    $win.e validate
	} $win
	return
    }
} ::kettle::ovalidate}

proc ::kettle::ovalidate::Bad {msg} {
    return -code error -errorcode {KETTLE OPTION VETO} $msg
}

# # ## ### ##### ######## ############# #####################
return
