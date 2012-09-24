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

# # ## ### ##### ######## ############# #####################
## Core API for recipe management. Not exported for build scripts,
## these are for build helper packages.

proc ::kettle::Sources {p} {
    variable srcdir $p
    return
}

proc ::kettle::Def {name description script} {
    variable recipe

    set help [Indent \
		  [Undent \
		       [join [lassign [split [string trim $description] \n] cmdline] \n]] \
		  {    }]
    if {$cmdline eq "--"} {
	set cmdline {}
    } {
	set cmdline " $cmdline"
    }

    if {[dict exists $recipe $name]} {
	# Extend definition.
	dict update recipe $name def {
	    dict lappend def script [list apply [list {} $script]]
	    dict append  def help   \n$help
	}
    } else {
	# First definition.
	dict set recipe $name script [list [list apply [list {} $script]]]
	dict set recipe $name help   $cmdline\n$help
	dict set recipe $name call   {}
    }
    return
}

proc ::kettle::DefHook {name base} {
    variable recipe
    if {![dict exists $recipe $base]} {
	dict set recipe $base {
	    script {}
	    help   {}
	    call   {}
	}
    }
    dict update recipe $base def {
	dict lappend def call $name
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

proc ::kettle::Run {name args} {
    variable recipe
    if {![dict exists $recipe $name]} {
	return -code error "No definition for \"$name\""
    }
    log {	run ($name) ...}
    foreach cmd [dict get $recipe $name script] {
	#puts |$cmd|
	eval $cmd $args
    }
    # Run the extension recipes.
    foreach r [lsort -unique [dict get $recipe $name call]] {
	Run $r
    }
    return
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

proc ::kettle::Recipes {} {
    variable recipe
    return [dict keys $recipe]
}

# # ## ### ##### ######## ############# #####################
## Internal helpers.

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
## State Initialization, Ensemblification

namespace eval ::kettle {
    variable recipe  {}
    variable verbose 0
    variable mydir   [file dirname [file normalize [info script]]]

    namespace export {[a-z]*} ;#def undef has run help recipes
    namespace ensemble create -prefixes 0 -unknown ::kettle::Unknown
}

# # ## ### ##### ######## ############# #####################
## Standard recipes.

## Recipe introspection.
kettle::Def recipes {
    --
    List all available recipes (build targets), without details.
} {
    puts [lsort -dict [kettle::Recipes]]
}

# Recipe help.
kettle::Def help {
    ?recipe?
    Print the help, all or for the specified recipe.
} {
    global argv
    # TODO: generalized argument processing. - mothership!
    set n [llength $argv] 
    if {$n != 1} {
	kettle::Help {Usage: }
    } else {
	kettle::Help {} [lindex $argv 0]
    }
}

# Standard graphical interface to the install recipes.
# TODO: Future: More dynamic adaptation to all recipes, through introspection.
kettle::Def gui {
    --
    Graphical interface to the installation process.
} {
    variable kettle::gui::INSTALLPATH

    package require Tk
    package require widget::scrolledwindow

    label  .l -text {Install Path: }
    entry  .e -textvariable ::INSTALLPATH
    button .i -command ::kettle::gui::install -text Install
    button .q -command ::_exit                -text Exit

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
    grid .i  -row 0 -column 2 -sticky new
    grid .q  -row 1 -column 2 -sticky new
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

proc ::kettle::gui::install {} {
    variable INSTALLPATH
    variable NOTE

    .i configure -state disabled
    .q configure -state disabled

    set NOTE {ok DONE}
    set fail [catch {
	set argv [list $INSTALLPATH]
	kettle::Run install
	::puts ""
	tag  [lindex $NOTE 0]
	::puts [lindex $NOTE 1]
    } e o]

    .i configure -state normal
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
## Automatic execution of command line processing and main,
## via interception of application exit.

rename ::exit ::kettle::done
proc   ::exit {{status 0}} {
    if {[catch {
	global argv tcl_platform
	if {![llength $argv]} {
	    if {$tcl_platform(platform) eq "windows"} {
		set cmd gui
	    } else {
		set cmd help
	    }
	} else {
	    set argv [lassign $argv cmd]
	}
	# TODO: Need generic customizable command line / option processing

	# Move old definition of exit back into place, in case a library
	# invoked by a recipe uses it. This way it won't recurse back
	# here, ad infinitum. We keep the other name active also.
	rename ::exit {}
	rename ::kettle::done ::exit
	proc ::kettle::done {args} { ::exit {*}$args }
	if {[catch {
	    kettle::Run $cmd
	}]} {
	    puts $::errorInfo
	    #kettle::Help {Usage: }
	}
	# See the rename above, no recursion!
	exit
    } msg]} {
	puts $::errorInfo
    }
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
## Ready

package provide kettle 0
return

# # ## ### ##### ######## ############# #####################
