# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Option handling

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::option {
    namespace export {[a-z]*}
    namespace ensemble create

    namespace import ::kettle::path
    namespace import ::kettle::io
    namespace import ::kettle::status
    namespace import ::kettle::ovalidate
}

# # ## ### ##### ######## ############# #####################
## State

namespace eval ::kettle::option {
    # Dictionaries for option configuration and definition.
    # The first maps option names to values, the other to the
    # definition, including state information about values.
    variable config {}
    variable def    {}

    # Dictionary containing the names of the options (as keys) which
    # will be used in keys into the work database maintained by the
    # 'status' command.
    variable work {}

    # Type of change getting propagated. List to handle nested propagations.
    variable change {}
}

# # ## ### ##### ######## ############# #####################
## API

proc ::kettle::option::define {o default {type any}} {
    variable config
    variable def
    variable work

    io trace {DEF'option $o}

    if {[dict exists $config $o]} {
	return -code error "Illegal redefinition of option $o."
    }

    # Validate the default before accepting the definition.
    ovalidate {*}$type $default

    dict set config $o $default     ; # Initial value is default.
    dict set work   $o .            ; # Use as key for work database
    dict set def    $o type   $type ; # Validation command.
    dict set def    $o user   0     ; # Flag, this option has been set
    dict set def    $o setter {}    ; # by the user. Plus code to
				      # validate and propagate changes.
    return
}

proc ::kettle::option::onchange {o arguments script args} {
    variable def
    lappend arguments option old new
    dict set def $o setter \
	[lambda@ ::kettle::option $arguments $script {*}$args]
    return
}

proc ::kettle::option::no-work-key {o} {
    variable work
    dict unset work $o
    return
}

proc ::kettle::option::exists {o} {
    variable config
    return [dict exists $config $o]
}

proc ::kettle::option::names {{pattern --*}} {
    variable config
    return [dict keys $config $pattern]
}

# set value, user choice
proc ::kettle::option::set {o value} {
    variable config
    variable def

    io trace {OPTION SET ($o) = "$value"}

    if {[dict exists $def $o type]} {
	ovalidate {*}[dict get $def $o type] $value
    }

    if {[dict exists $config $o]} {
	::set has 1
	::set old [dict get $config $o]
    } else {
	::set has 0
	::set old {}
    }  

    dict set config $o $value
    dict set def    $o user 1

    # Propagate choice, if possible
    reportchange user $o $old $value
    return
}

# set value, system choice, new default. ignored if a user has chosen
# a value for the option.
proc ::kettle::option::set-default {o value} {
    variable config
    variable def
    variable change

    if {[lindex $change end] eq "user"} {
	set $o $value
	return
    }

    if {![dict exists $def $o]} {
	return -code error "Unable to set default of undefined option $o."
    }

    io trace {OPTION SET-D ($o) =[dict get $def $o user]= "$value"}

    if {[dict exists $def $o type]} {
	ovalidate {*}[dict get $def $o type] $value
    }

    if {[dict get $def $o user]} return

    ::set old [dict get $config $o]
    dict set config $o $value
    # Propagate new default.
    reportchange default $o $old $value
    return
}

# set value, override anything, no propagation
proc ::kettle::option::set! {o v} {
    variable config
    #io trace {  SET! $o $v}
    dict set config $o $v
    return
}

proc ::kettle::option::unset {o} {
    variable config
    dict unset config $o
    return
}

proc ::kettle::option::get {o} {
    variable config

    if {![dict exists $config $o]} {
	return -code error "Unable to retrieve unknown option $o."
    }

    return [dict get $config $o]
}

proc ::kettle::option::reportchange {type o old new} {
    variable def
    if {![dict exists $def $o setter]} return
    ::set setter [dict get $def $o setter]
    if {$setter eq {}} return
    variable change
    lappend change $type
    try {
	{*}$setter $o $old $new
    } trap {KETTLE OPTION VETO} {e opts} {
	return {*}${opts} "Bad option $o: $e"
    }
    ::set change [lreplace $change end end]
    return
}

proc ::kettle::option::veto {msg} {
    return -code error -errorcode {KETTLE OPTION VETO} $msg
}

proc ::kettle::option::save {} {
    variable config

    ::set path   [kettle path tmpfile config_]
    ::set serial [dict filter $config key --*]

    dict unset serial --state
    dict unset serial --config

    kettle path write $path $serial
    io trace {options saved to    $path}
    return $path
}

proc ::kettle::option::load {file} {
    io trace {options loaded from $file}
    variable config

    # Note: See how this bypasses all the setters. The configuration
    # is loaded as is. With setters active the state may change
    # from what we loaded, depending on order of options. Bad.
    ::set config [dict merge $config [kettle path cat $file]]

    # Special handling of --verbose, i.e. activate, as if the setter
    # had been run.
    if {[get --verbose]} { io trace-on }
    return
}

proc ::kettle::option::config {args} {
    variable config
    variable def
    variable work

    # Apply the overrides. We use the regular set command to invoke
    # all relevant setter hooks. Afterward we retrieve the modified
    # configuration (*) and restore the old state.
    #
    # (Ad *) Well, actually just the part needed to key the work
    #        database.

    ::set sconfig $config
    ::set sdef    $def
    foreach {o v} $args { set $o $v }
    ::set serial [dict filter $config script {o v} { dict exists $work $o }]
    ::set sdef   $def
    ::set config $sconfig

    # Now we have the modified configuration a child process will
    # compute for itself given the --config and overrides as options
    # as key part for the work database.

    return [DictSort $serial]
}

proc ::kettle::option::DictSort {dict} {
    array set a $dict
    ::set out [list]
    foreach key [lsort -dict [array names a]] {
	lappend out $key $a($key)
    }
    return $out
}

# # ## ### ##### ######## ############# #####################
## Initialization

apply {{} {
    global tcl_platform

    # - -- --- ----- -------- -------------
    define   --exec-prefix {}
    onchange --exec-prefix {} {
	# Implied arguments: option old new
	::set new [path norm $new]
	set!        --exec-prefix $new
	set-default --bin-dir     $new/bin
	set-default --lib-dir     $new/lib
    }

    define   --bin-dir {}
    onchange --bin-dir {} { set! --bin-dir [path norm $new] }
    define   --lib-dir {}
    onchange --lib-dir {} { set! --lib-dir [path norm $new] }

    define   --prefix {}
    onchange --prefix {} {
	# Implied arguments: option old new
	::set new [path norm $new]
	set!        --prefix      $new
	set-default --exec-prefix $new
	set-default --man-dir     $new/man
	set-default --html-dir    $new/html
	set-default --include-dir $new/include
    }

    define   --man-dir     {}
    onchange --man-dir     {} { set! --man-dir [path norm $new] }
    define   --html-dir    {}
    onchange --hmtl-dir    {} { set! --html-dir [path norm $new] }
    define   --include-dir {}
    onchange --include-dir {} { set! --include-dir [path norm $new] }

    set-default --prefix [file dirname [file dirname [info library]]]
    # -> man, html, exec-prefix -> bin, lib
    set-default --bin-dir [file dirname [path norm [info nameofexecutable]]]
    set-default --lib-dir [info library]

    define --ignore-glob {
	*~ _FOSSIL_ .fslckout .fos .git .svn CVS .hg RCS SCCS
	*.bak *.bzr *.cdv *.pc _MTN _build _darcs _sgbak blib
	autom4te.cache cover_db ~.dep ~.dot ~.nib ~.plst
    }
    no-work-key --ignore-glob

    # - -- --- ----- -------- -------------
    # File action. Default on (== dry-run off).

    define      --dry 0 boolean
    no-work-key --dry

    # - -- --- ----- -------- -------------
    # Tracing of internals. Default off.

    define      --verbose off boolean
    no-work-key --verbose
    onchange    --verbose {} {
	if {$new} { io trace-on }
    }

    # - -- --- ----- -------- -------------
    # Output colorization. Default platform dependent.

    define      --color off boolean
    no-work-key --color
    if {$tcl_platform(platform) eq "windows"} {
	set-default --color off
    } else {
	if {[catch {
	    package require Tclx
	}] || ![fstat stdout tty]} {
	    set-default --color off
	} else {
	    set-default --color on
	}
    }

    # - -- --- ----- -------- -------------
    # State and configuration handling for sub-processes. Default none.

    define      --state {} rfile
    no-work-key --state
    onchange    --state {} { status load $new }

    define      --config {} rfile
    no-work-key --config
    onchange    --config {} { load $new }

    # - -- --- ----- -------- -------------
    # Default goals to use when invoked with none.
    # Platform dependent.

    if {$tcl_platform(platform) eq "windows"} {
	set @goals gui
    } else {
	set @goals help
    }

    # - -- --- ----- -------- -------------
} ::kettle::option}

# # ## ### ##### ######## ############# #####################
return
