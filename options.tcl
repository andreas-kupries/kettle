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
}

# # ## ### ##### ######## ############# #####################
## State

namespace eval ::kettle::option {
    # Dictionary, map option names to values.
    variable config {}
}

# # ## ### ##### ######## ############# #####################
## API

proc ::kettle::option::define {o arguments script args} {
    variable config

    io trace {DEF'option $o}

    if {[dict exists $config $o]} {
	return -code error "Illegal redefinition of option $o."
    }

    lappend arguments option old new

    dict set config $o value {}
    dict set config $o user  0
    dict set config $o setter \
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

    if {[dict exists $config $o] && [dict exists $config $o value]} {
	::set old [dict get $config $o value]
    } else {
	::set old {}
    }  

    dict set config $o value $value
    dict set config $o user 1

    # Propagate choice, if possible
    if {![dict exists $config $o setter]} return
    {*}[dict get $config $o setter] $o $old $value
    return
}

# set value, system choice, new default. ignored if a user has chosen
# a value for the option.
proc ::kettle::option::setd {o value} {
    variable config

    if {![dict exists $config $o]} {
	return -code error "Unable to set default of undefined option $o."
    }

    if {[dict get $config $o user]} return

    ::set old [dict get $config $o value]
    dict set config $o value $value
    # Propagate new default.
    {*}[dict get $config $o setter] $o $old $value
    return
}

# set value, override anything, no propagation
proc ::kettle::option::set! {o v} {
    variable config
    #io trace {  SET! $o $v}
    dict set config $o value $v
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

    return [dict get $config $o value]
}

# # ## ### ##### ######## ############# #####################
## Initialization

apply {{} {
    global tcl_platform
    variable config

    define --exec-prefix {} {
	# Implied arguments: option old new
	::set new [path norm $new]
	set! --exec-prefix $new
	setd --prefix      $new
	setd --bin-dir     $new/bin
	setd --lib-dir     $new/lib
    }

    define --bin-dir {} { set! --bin-dir [path norm $new] }
    define --lib-dir {} { set! --lib-dir [path norm $new] }

    define --prefix {} {
	# Implied arguments: option old new
	::set new [path norm $new]
	set! --prefix      $new
	setd --man-dir     $new/man
	setd --html-dir    $new/html
	setd --include-dir $new/include
    }

    define --man-dir     {} { set! --man-dir     [path norm $new] }
    define --html-dir    {} { set! --html-dir    [path norm $new] }
    define --include-dir {} { set! --include-dir [path norm $new] }

    setd --exec-prefix [file dirname [file dirname [info library]]]
    # -> bin, lib, prefix -> man, html

    setd --bin-dir [file dirname [path norm [info nameofexecutable]]]
    setd --lib-dir [info library]

    define --ignore-glob {} {}
    setd --ignore-glob {
	*~ _FOSSIL_ .fslckout .fos .git .svn CVS .hg RCS SCCS
	*.bak *.bzr *.cdv *.pc _MTN _build _darcs _sgbak blib
	autom4te.cache cover_db ~.dep ~.dot ~.nib ~.plst
    }

    # Default file action: Do
    define --dry {} {}
    setd   --dry 0

    # Default tracing: Off
    define --verbose {} {
	if {$new} { io trace-on }
    }
    setd --verbose 0

    # Default colorization: Platform dependent.
    define --color {} {}
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

    # Default goals
    if {$tcl_platform(platform) eq "windows"} {
	set @goals gui
    } else {
	set @goals help
    }
} ::kettle::option}

# # ## ### ##### ######## ############# #####################
return
