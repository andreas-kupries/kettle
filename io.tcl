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

    # Map to detect and separate escape sequences from regular text.
    # Plus the actions to take per escape sequence.
    variable emap    {}
    variable eaction {}

    # Partial escape sequence from the end of the last puts processed.
    variable buffer {}

    # Currently active tag, per channel going into the text widget.
    variable active {
	stdout {}
	stderr red
    }
}

# # ## ### ##### ######## ############# #####################
## Message API. puts replacement

proc ::kettle::io::setwidget {t} {
    variable textw $t

    # Match to the escape definitions at the end, and the mapping in
    # 'puts'.

    # semantic tags
    $t tag configure stdout                       ;# -font {Helvetica 8}
    $t tag configure stderr -background red       ;# -font {Helvetica 12}

    # color tags
    $t tag configure red    -background red       ;# -font {Helvetica 8}
    $t tag configure green  -background green     ;# -font {Helvetica 8}
    $t tag configure blue   -background lightblue ;# -font {Helvetica 8}
    $t tag configure white  -background white     ;# -font {Helvetica 8}
    $t tag configure yellow -background yellow    ;# -font {Helvetica 8}
    $t tag configure cyan   -background cyan      ;# -font {Helvetica 8}
    return
}

proc ::kettle::io::ingui {script} {
    variable textw
    if {$textw eq {}} return
    uplevel 1 $script
}

proc ::kettle::io::interm {script} {
    variable textw
    if {$textw ne {}} return
    uplevel 1 $script
}

proc ::kettle::io::puts {args} {
    variable textw
    variable emap
    variable eaction
    variable buffer
    variable active

    if {$textw eq {}} {
	# Terminal mode.
	::puts {*}$args
	return
    }

    # GUI mode. We scan the input for escape sequences.

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

    # Quick handling of \r, convert to newlines.
    # Get the buffer also.
    set text ${buffer}[string map [list \r \n] $text]
    set buffer ""
    if {$newline} { append text \n }

    # Scan for escape sequences, mark them, and break the input apart
    # at their borders. Then iterate over the fragments, map to and
    # execute associated actions.

    foreach piece [split [string map $emap $text] \0] {
	if {[dict exists $eaction $piece]} {
	    # Escape sequence, or partial, modify tag state
	    {*}[dict get $eaction $piece]
	} elseif {$piece ne {}} {
	    # Plain text, extend display
	    # Note: We split along lines, and leave the line-endings
	    # untagged!

	    foreach line [lreverse \
			      [lassign \
				   [lreverse \
					[split $piece \n]] \
				   last]] {
		$textw insert end-1c $line [Tag] \n {}
	    }
	    $textw insert end-1c $last [Tag]
	}
    }
    update
    return
}

proc ::kettle::io::Tag {} {
    variable active
    upvar 1 chan chan
    dict get $active $chan
}

proc ::kettle::io::Tag! {tag} {
    variable active
    upvar 1 chan chan
    if {$tag eq "reset"} {
	# Switch to base state as per the channel.
	if {$chan eq "stdout"} {
	    set tag {}
	} else {
	    set tag red
	}
    }
    dict set active $chan $tag
    return
}

proc ::kettle::io::Buffer {text} {
    variable buffer
    append buffer $text
    return
}

# # ## ### ##### ######## ############# #####################
## Tracing API

proc ::kettle::io::trace {text} {
    variable trace
    if {!$trace} return
    debug { puts [pid]:\t[uplevel 1 [list subst $text]] }
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

proc ::kettle::io::Escape {chars} {
    # Colorization is system and user choice.
    if {![kettle option get --color]} return
    puts -nonewline \033\[${chars}m
    return
}

# # ## ### ##### ######## ############# #####################
## Initialization

apply {{} {
    variable emap    {}
    variable eaction {}

    # Full color escape sequences. These modify the widget state.
    foreach {c t} {
	31 red		32 green	33 yellow	34 blue
	35 magenta	36 cyan		37 white	0  reset
    } {
	lappend emap    \033\[${c}m \0\033\[${c}m\0
	lappend eaction \033\[${c}m [list Tag! $t]
    }
    # Partial escape sequences. These are buffered for the next puts
    # to complete them.
    foreach c {
	\033\[31	\033\[32	\033\[33	\033\[34
	\033\[35	\033\[36	\033\[37	\033\[3
	\033\[0		\033\[		\033
    } {
	lappend emap    $c \0${c}\0
	lappend eaction $c [list Buffer $c]
    }
} ::kettle::io}

apply {{} {
    # User visible commands to select color, direct or semantically.
    foreach {tag chars note} {
	ok      32 { = green   }
	warn    33 { = yellow  }
	err     31 { = red     }
	note    34 { = blue    }
	debug   35 { = magenta }
	red     31 {}
	green   32 {}
	yellow  33 {}
	blue    34 {}
	magenta 35 {}
	cyan    36 {}
	white   37 {}
	reset    0 {}
    } {
	interp alias {} ::kettle::io::H$tag {} ::kettle::io::Escape $chars
	if {$tag eq "reset"} continue
	interp alias {} ::kettle::io::$tag {} ::kettle::io::Color $tag
    }
}}

# # ## ### ##### ######## ############# #####################
return

