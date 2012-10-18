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
}

# # ## ### ##### ######## ############# #####################
## State

namespace eval ::kettle::option {
    # Dictionaries for option configuration and definition.
    # The first maps option names to values, the other to the
    # definition, including state information about values.
    variable config {}
    variable def    {}
}

# # ## ### ##### ######## ############# #####################
## API

proc ::kettle::option::define {o arguments script args} {
    variable config
    variable def

    io trace {DEF'option $o}

    if {[dict exists $config $o]} {
	return -code error "Illegal redefinition of option $o."
    }

    lappend arguments option old new

    dict set config $o {}
    dict set def    $o user  0
    dict set def    $o setter \
	[lambda@ ::kettle::option $arguments $script {*}$args]
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
    reportchange $o $old $value
    return
}

# set value, system choice, new default. ignored if a user has chosen
# a value for the option.
proc ::kettle::option::setd {o value} {
    variable config
    variable def

    if {![dict exists $def $o]} {
	return -code error "Unable to set default of undefined option $o."
    }

    if {[dict get $def $o user]} return

    ::set old [dict get $config $o]
    dict set config $o $value
    # Propagate new default.
    reportchange $o $old $value
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

proc ::kettle::option::reportchange {o old new} {
    variable def
    if {![dict exists $def $o setter]} return
    try {
	{*}[dict get $def $o setter] $o $old $new
    } trap {KETTLE OPTION VETO} {e opts} {
	return {*}${opts} "Bad option $o: $e"
    }
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

    # Apply the overrides. We use the regular set command to invoke
    # all relevant setter hooks. Afterward we retrieve the modified
    # configuration and restore the old state.

    ::set saved $config
    foreach {o v} $args { set $o $v }
    ::set serial [dict filter [dict filter $config key --*] script {o v} {
	expr {($o ne "--state") &&
	      ($o ne "--config") &&
	      ($o ne "--log") &&
	      ![string match --with-* $o] &&
	      ![string match --log-*  $o]
	  }
    }]
    ::set config $saved

    # Now we have the modified configuration a child process will
    # compute for itself given the --config and overrides as options
    # as key part for the work database.

    return [DictSort $serial]
}

proc ::kettle::option::DictSort {dict} {
    array set a $dict
    set out [list]
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
    define --exec-prefix {} {
	# Implied arguments: option old new
	::set new [path norm $new]
	set! --exec-prefix $new
	setd --bin-dir     $new/bin
	setd --lib-dir     $new/lib
    }

    define --bin-dir {} { set! --bin-dir [path norm $new] }
    define --lib-dir {} { set! --lib-dir [path norm $new] }

    define --prefix {} {
	# Implied arguments: option old new
	::set new [path norm $new]
	set! --prefix      $new
	setd --exec-prefix $new
	setd --man-dir     $new/man
	setd --html-dir    $new/html
	setd --include-dir $new/include
    }

    define --man-dir     {} { set! --man-dir     [path norm $new] }
    define --html-dir    {} { set! --html-dir    [path norm $new] }
    define --include-dir {} { set! --include-dir [path norm $new] }

    setd --prefix [file dirname [file dirname [info library]]]
    # -> man, html, exec-prefix -> bin, lib

    setd --bin-dir [file dirname [path norm [info nameofexecutable]]]
    setd --lib-dir [info library]

    define --ignore-glob {} {}
    setd --ignore-glob {
	*~ _FOSSIL_ .fslckout .fos .git .svn CVS .hg RCS SCCS
	*.bak *.bzr *.cdv *.pc _MTN _build _darcs _sgbak blib
	autom4te.cache cover_db ~.dep ~.dot ~.nib ~.plst
    }

    # - -- --- ----- -------- -------------
    # File action. Default on.

    define --dry {} {
	if {[string is boolean -strict $new]} return
	veto "Expected boolean, but got \"$new\""
    }
    setd --dry 0

    # - -- --- ----- -------- -------------
    # Tracing of internals. Default off.

    define --verbose {} {
	if {[string is boolean -strict $new]} {
	    if {$new} { io trace-on }
	    return
	}
	veto "Expected boolean, but got \"$new\""
    }
    setd --verbose 0

    # - -- --- ----- -------- -------------
    # Output colorization. Default platform dependent.

    define --color {} {
	if {[string is boolean -strict $new]} return
	veto "Expected boolean, but got \"$new\""
    }
    if {$tcl_platform(platform) eq "windows"} {
	setd --color 0
    } else {
	if {[catch {
	    package require Tclx
	}] || ![fstat stdout tty]} {
	    setd --color 0
	} else {
	    setd --color 1
	}
    }

    # - -- --- ----- -------- -------------
    # State and configuration handling for sub-processes. Default none.

    define --state {} {
	if {$new eq {}} return
	status load $new
    }
    setd --state {}

    define --config {} {
	if {$new eq {}} return
	load $new
    }
    setd --config {}

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
