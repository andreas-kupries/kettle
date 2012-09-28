# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Message output. Terminal/GUI support. Colorization.
## User messages, and system tracing.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::io {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## State

namespace eval ::kettle::io {
    # Boolean flag. True - Tracing of internals is active.
    variable trace 0

    # Text widget to write to, in gui mode.
    # gui is active <==> this is a non-empty string.
    variable textw {}

    # Tag information for output. Only relevant in gui mode.
    variable tag {}
}

# # ## ### ##### ######## ############# #####################
## Message API. puts replacement

proc ::kettle::io::setwidget {t} {
    variable textw $t

    # Match to the hilit definitions below.

    # semantic tags
    $t tag configure stdout                       ;# -font {Helvetica 8}
    $t tag configure stderr -background red       ;# -font {Helvetica 12}
    $t tag configure err    -background red       ;# -font {Helvetica 12}
    $t tag configure ok     -background green     ;# -font {Helvetica 8}
    $t tag configure warn   -background yellow    ;# -font {Helvetica 12}
    $t tag configure note   -background lightblue ;# -font {Helvetica 8}
    $t tag configure debug  -background cyan      ;# -font {Helvetica 12}

    # color tags
    $t tag configure red    -background red    ;# -font {Helvetica 8}
    $t tag configure green  -background green  ;# -font {Helvetica 8}
    $t tag configure blue   -background blue   ;# -font {Helvetica 8}
    $t tag configure white  -background white  ;# -font {Helvetica 8}
    $t tag configure yellow -background yellow ;# -font {Helvetica 8}
    $t tag configure cyan   -background cyan   ;# -font {Helvetica 8}
    return
}

proc ::kettle::io::puts {args} {
    variable textw

    if {$textw eq {}} {
	# Terminal mode.
	::puts {*}$args
	return
    }

    # GUI mode.

    variable tag
    set newline 1
    if {[lindex $args 0] eq "-nonewline"} {
	set newline 0
	set args [lrange $args 1 end]
    }

    if {[llength $args] == 2} {
	lassign $args chan text
	if {$chan ni {stdout stderr}} {
	    # Non-standard channels are not redirected to the GUI
	    ::puts {*}$args
	    return
	}
    } else {
	set text [lindex $args 0]
	set chan stdout
    }

    # chan <=> tag, if not overriden
    ## TODO 'Files left' ?!
    if {[string match {Files left*} $text]} {
	set tag warn
	set text \n$text
    }

    if {$tag eq {}} { set tag $chan }
    #::puts $tag/$text

    $textw insert end-1c $text $tag
    if {$newline} { 
	$textw insert end-1c \n
    }
    update
    return
}

# # ## ### ##### ######## ############# #####################
## Tracing API

proc ::kettle::io::trace {text} {
    variable trace
    if {!$trace} return
    debug { puts [uplevel 1 [list subst $text]] }
    return
}

proc ::kettle::io::trace-on {} {
    variable trace 1
    return
}

# # ## ### ##### ######## ############# #####################
## Internals

proc ::kettle::io::Color {t {script {}}} {
    H$t
    if {$script ne {}} {
	uplevel 1 $script
	Hreset
    }
}

proc ::kettle::io::Hilit {t chars} {
    variable textw
    variable tag $t
    if {$textw ene {}} return
    ## TODO ## check for non-tty/win to disable.
    ## Requires TclX however (fstat stdout tty)
    ::puts -nonewline $chars
    return
}

# # ## ### ##### ######## ############# #####################
## Initialization

apply {{} {
    foreach tag {
	ok    warn   err   note    
	debug red    green blue    
	white yellow cyan  magenta 
    } {
	interp alias {} ::kettle::$tag {} ::kettle::Color $tag
    }

    foreach {tag chars note} {
	ok      \033\[32m { = green   }
	warn    \033\[33m { = yellow  }
	err     \033\[31m { = red     }
	note    \033\[34m { = blue    }
	debug   \033\[35m { = magenta }
	red     \033\[31m {}
	green   \033\[32m {}
	yellow  \033\[33m {}
	blue    \033\[34m {}
	magenta \033\[35m {}
	cyan    \033\[36m {}
	white   \033\[37m {}
	reset   \033\[0m  {}
    } {
	set t $tag ; if {$tag eq "reset"} { set t {} }
	interp alias {} ::kettle::H$tag {} ::kettle::Hilit $t $chars
    }
}}

# # ## ### ##### ######## ############# #####################
return

