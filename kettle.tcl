## core.tcl --
# # ## ### ##### ######## ############# #####################
#
#	Kettle Core.
#	Recipe Database, standard recipes, generic main
#	application code, and auto-extension.
#
# Copyright (c) 2012 Andreas Kupries

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
namespace eval ::kettle {}

# # ## ### ##### ######## ############# #####################
## API. For use in recipes.

proc ::kettle::path {path} {
    variable mydir
    return [file join $mydir $path]
}

proc ::kettle::norm {path} {
    return [file dirname [file normalize $path/__]]
}

proc ::kettle::verbose {} {
    variable verbose 1
    return
 }

proc ::kettle::log {text} {
    variable verbose
    if {!$verbose} return
    puts [uplevel 1 [list subst $text]]
    return
}

proc ::kettle::sources {{path {}}} {
    variable srcdir
    return [file join $srcdir $path]
}

namespace eval ::kettle {
    variable verbose 0
    variable mydir   [file dirname [file normalize [info script]]]
}

# # ## ### ##### ######## ############# #####################
## Command line option database, and defaults.

proc ::kettle::option? {o} {
    variable config
    return [dict exists $config $o]
}

proc ::kettle::option: {o {v {}}} {
    variable config
    dict set config $o $v
    return $v
}

proc ::kettle::option-get {o} {
    variable config
    return [dict get config $o]
}

namespace eval ::kettle {
    variable config {}
}

apply {{} {
    variable config

    dict set config --exec-prefix [file dirname [file dirname [info library]]]
    dict set config --bin-dir     [file dirname [file dirname [file normalize [info nameofexecutable]/___]]]
    dict set config --lib-dir     [info library]

    dict set config --prefix      [dict get $config --exec-prefix]
    dict set config --man-dir     [dict get $config --prefix]/man
    dict set config --html-dir    [dict get $config --prefix]/man

} ::kettle}

# # ## ### ##### ######## ############# #####################
## Core API for recipe management. Not exported for build scripts,
## these are for build helper packages.

proc ::kettle::Def {name description script} {
    variable recipe

    InitRecipe $name
    dict update recipe $name def {
	dict lappend def script [list apply [list {} $script]]
	dict append  def help   \n[Reflow $description]
    }
    return
}

proc ::kettle::SetParent {name parent} {
    variable recipe

    InitRecipe $name
    dict set recipe $name parent $parent
    return
}

proc ::kettle::InitRecipe {name} {
    variable recipe
    if {[dict exists $recipe $name]} return
    dict set recipe $name {
	script {}
	help   {}
	parent {}
    }
    return
}

proc ::kettle::Undef {name} {
    variable recipe
    if {![dict exists $recipe $name]} {
	return -code error "No definition for \"$name\""
    }
    dict unset recipe $name
    return
}

proc ::kettle::Has {name} {
    variable recipe
    return [dict exists $recipe $name]
}

proc ::kettle::Recipes {} {
    variable recipe
    return [dict keys $recipe]
}

proc ::kettle::Help {prefix {topic {}}} {
    global   argv0
    variable recipe
    append prefix $argv0 " "
    if {[llength [info level 0]] == 3} {
	if {![dict exists $recipe $topic]} {
	    return -code error "No definition for \"$topic\""
	}
	puts "\n$prefix${topic}[dict get $recipe $topic help]"
    } else {
	foreach topic [lsort -dict [dict keys $recipe]] {
	    puts "\n$prefix${topic}[dict get $recipe $topic help]"
	}
    }
    return
}

proc ::kettle::Run {name} {
    variable recipe
    variable done

    if {![dict exists $recipe $name]} {
	return -code error "No definition for \"$name\""
    }

    # Ignore goals already executed.
    if {[dict exists $done $name]} return
    dict set done $name .

    # Determine the recipe's children and run them first.
    dict for $recipe {c v} {
	if {![dict get $v parent] eq $name} continue
	Run $c
    }

    # Now run the recipe itself
    log {	run ($name) ...}
    foreach cmd [dict get $recipe $name script] {
	#puts |$cmd|
	eval $cmd
    }
    return
}

namespace eval ::kettle {
    variable recipe {}
    variable done   {}
}

# # ## ### ##### ######## ############# #####################
## Internal helpers for help text processing

proc ::kettle::Reflow {help} {
    return [Indent [Undent [string trim $help]] {    }]
}

proc ::kettle::Indent {text prefix} {
    set text [string trimright $text]
    set res {}
    foreach line [split $text \n] {
	if {[string trim $line] eq {}} {
	    lappend res {}
	} else {
	    lappend res $prefix[string trimright $line]
	}
    }
    return [join $res \n]
}

proc ::kettle::Undent {text} {
    if {$text eq {}} { return {} }

    set lines [split $text \n]
    set ne {}
    foreach l $lines {
	if {[string length [string trim $l]] == 0} continue
	lappend ne $l
    }

    set lcp [LCP $ne]
    if {$lcp eq {}} { return $text }

    regexp "^(\[\t \]*)" $lcp -> lcp
    if {$lcp eq {}} { return $text }

    set len [string length $lcp]

    set res {}
    foreach l $lines {
	if {[string trim $l] eq {}} {
	    lappend res {}
	} else {
	    lappend res [string range $l $len end]
	}
    }
    return [join $res \n]
}

proc ::kettle::LCP {list} {
    if {[llength $list] <= 1} {
	return [lindex $list 0]
    }

    set list [lsort $list]
    set min [lindex $list 0]
    set max [lindex $list end]

    # Min and max are the two strings which are most different. If
    # they have a common prefix, it will also be the common prefix for
    # all of them.

    # Fast bailouts for common cases.

    set n [string length $min]
    if {$n == 0}      { return "" }
    if {$min eq $max} { return $min }

    set prefix ""
    set i 0
    while {[string index $min $i] eq [string index $max $i]} {
	append prefix [string index $min $i]
	if {[incr i] > $n} {break}
    }
    return $prefix
}

# # ## ### ##### ######## ############# #####################
## Standard recipes.

## Recipe introspection.
kettle::Def recipes {
    List all available recipes (build targets), without details.
} {
    puts [lsort -dict [kettle::Recipes]]
}

# Recipe help.
kettle::Def help {
    Print the help.
} {
    kettle::Help {Usage: }
}

# Standard graphical interface to the install recipes.
# TODO: Future: More dynamic adaptation to all recipes, through introspection.
kettle::Def gui {
    Graphical interface to the system.
} {
    variable kettle::gui::INSTALLPATH

    # Dynamic adaptation to the config database contents, and
    # ability to extend that database from the GUI.
    # ==> ttk notebook, tree.

    package require Tk
    package require widget::scrolledwindow

    label  .l -text {Install Path: }
    entry  .e -textvariable ::INSTALLPATH

    foreach r [lsort -dict [kettle::Recipes]] {
	button .i$r -command [list ::kettle::gui::run $r] -text $r
    }
    button .q -command ::_exit -text Exit

    widget::scrolledwindow .st -borderwidth 1 -relief sunken
    text   .t
    .st setwidget .t

    .t tag configure stdout -font {Helvetica 8}
    .t tag configure stderr -background red       -font {Helvetica 12}
    .t tag configure ok     -background green     -font {Helvetica 8}
    .t tag configure warn   -background yellow    -font {Helvetica 12}
    .t tag configure note   -background lightblue -font {Helvetica 8}

    grid .l  -row 0 -column 0 -sticky new
    grid .e  -row 0 -column 1 -sticky new

    set rr 0
    foreach r [lsort -dict [kettle::Recipes]] {
	grid .i$r  -row $rr -column 2 -sticky new
	incr rr
    }
    grid .q -row $rr -column 2 -sticky new
    grid .st -row 1 -column 0 -sticky swen -columnspan 2

    grid rowconfigure . 0 -weight 0
    grid rowconfigure . 1 -weight 1

    grid columnconfigure . 0 -weight 0
    grid columnconfigure . 1 -weight 1
    grid columnconfigure . 2 -weight 0

    set INSTALLPATH [info library]

    # Redirect all output into our log window, disable uncontrolled exit.
    # The latter may come out of deeper layers, like, for example, critcl
    # compilation.

    rename ::puts ::kettle::gui::puts
    proc   ::puts {args} {
	variable ::kettle::gui::tag
	set newline 1
	if {[lindex $args 0] eq "-nonewline"} {
	    set newline 0
	    set args [lrange $args 1 end]
	}
	if {[llength $args] == 2} {
	    lassign $args chan text
	    if {$chan ni {stdout stderr}} {
		::kettle::gui::puts {*}[lrange [info level 0] 1 end]
		return
	    }
	} else {
	    set text [lindex $args 0]
	    set chan stdout
	}
	# chan <=> tag, if not overriden
	if {[string match {Files left*} $text]} {
	    set tag warn
	    set text \n$text
	}
	if {$tag eq {}} { set tag $chan }
	#::kettle::gui::puts $tag/$text

	.t insert end-1c $text $tag
	set tag {}
	if {$newline} { 
	    .t insert end-1c \n
	}
	update
	return
    }

    rename ::exit   ::_exit
    proc   ::exit {{status 0}} {
	::kettle::gui::tag ok
	::puts DONE
	return
    }

    wm protocol . WM_DELETE_WINDOW ::_exit

    # And start to interact with the user.
    vwait forever
    return
}

namespace eval kettle::gui {}

proc ::kettle::gui::tag {t} {
    variable tag $t
    return
}

proc ::kettle::gui::run {goal} {
    variable INSTALLPATH
    variable NOTE

    #set argv [list $INSTALLPATH]
    #=> update option database
    option: --lib-dir $INSTALLPATH

    # TODO: MUST disable all buttons.
    .i$goal configure -state disabled
    .q configure -state disabled

    # TODO look for code changing this on failure.
    set NOTE {ok DONE}
    set fail [catch {
	kettle::Run $goal
	::puts ""
	tag    [lindex $NOTE 0]
	::puts [lindex $NOTE 1]
    } e o]

    # TODO: MUST re-enable all buttons.
    .i$goal configure -state normal
    .q configure -state normal -bg green

    if {$fail} {
	# rethrow
	return {*}$o $e
    }
    return
}

namespace eval kettle::gui {
    variable tag {}

    namespace export tag install
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## Core application functionality.
## - Command line processing
## - Declaration processing
## - Goal processing

namespace eval ::kettle {
    variable goals  {}
    variable decls  {}
}

proc ::kettle::ProcessDecls {} {
    variable decls
    variable srcdir [file dirname $decls]

    if {[catch {
	::source $decls
    }]} {
	# Report troubles in the declarations and abort.
	puts stderr $::errorInfo
	done 1
    }
    return
}

proc ::kettle::ProcessCmdline {} {
    global argv

    variable goals
    variable decls

    if {[lindex $argv 0] eq {-f}} {
	set argv [lassign $argv __ path]
	set decls [norm $path]

    } elseif {[file exists build.tcl]} {
	set decls [norm build.tcl]

    } else {
	puts stderr "Build declaration file neither specified, nor found"
	done 1
    }

    if {[lindex $argv 0] eq {-v}} {
	set argv [lrange $argv 1 end]
	verbose
    }

    set goals {}
    while {[llength $argv]} {
	set o [lindex $argv 0]
	switch -glob -- $o {
	    --* {
		option: $o [lindex $argv 1]
		set argv [lrange $argv 2 end]
	    }
	    default {
		lappend goals $o
		set argv [lrange $argv 1 end]
	    }
	}
    }
    return
}

proc ::kettle::ProcessGoals {} {
    FixExit
    set goals [Goals]

    if {[catch {
	foreach goal $goals {
	    Run $goal
	}
    }]} {
	puts $::errorInfo
	#kettle::Help {Usage: }
    }
    # See the rename above, no recursion!
    ::exit 0
}

proc ::kettle::Goals {} {
    variable goals
    global tcl_platform
    if {![llength $goals]} {
	if {$tcl_platform(platform) eq "windows"} {
	  lappend goals gui
	} else {
	    lappend goals help
	}
    }
    return $goals
}

# # ## ### ##### ######## ############# #####################
## Automatic execution of command line processing and main,
## via interception of application exit.

rename ::exit ::kettle::done
proc   ::exit {{status 0}} {
    if {[catch {
	kettle::ProcessGoals
    } msg]} {
	puts $::errorInfo
    }
}

proc ::kettle::FixExit {} {
    # Move the old definition of exit back into place, in case a
    # library invoked by a recipe uses it. This way it won't recurse
    # back here, ad infinitum. We keep the other name active also.

    rename ::exit         {}
    rename ::kettle::done ::exit

    proc ::kettle::done {args} {
	::exit {*}$args
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Automatic loading of kettle packages when encountering unknown
## kettle commands, via the ensemble unknown handler.

proc ::kettle::Unknown {args} {
    set package kettle::[lindex $args 1]
    #puts "...Loading $package"
    if {[catch {
	package require $package
    }]} {
	puts $::errorInfo
	kettle::done 1
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Export

namespace eval ::kettle {
    namespace export {[a-z]*} ;#def undef has run help recipes
    namespace ensemble create -prefixes 0 -unknown ::kettle::Unknown
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle 0
return

# # ## ### ##### ######## ############# #####################
