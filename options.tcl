# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Option handling

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::option {
    namespace export {[a-z]*}
    namespace ensemble create

    namespace import ::kettle::path
}

# # ## ### ##### ######## ############# #####################
## State

namespace eval ::kettle::option {
    # Dictionary, map option names to values.
    variable config {}

}

# # ## ### ##### ######## ############# #####################
## API

proc ::kettle::option::exists {o} {
    variable config
    return [dict exists $config $o]
}

proc ::kettle::option::set {o {v {}}} {
    variable config
    dict set config $o $v
    return $v
}

proc ::kettle::option::get {o} {
    variable config
    return [dict get $config $o]
}

# # ## ### ##### ######## ############# #####################
## Initialization

apply {{} {
    global tcl_platform
    variable config

    dict set config --exec-prefix [file dirname [file dirname [info library]]]
    dict set config --prefix      [dict get $config --exec-prefix]

    dict set config --bin-dir     [file dirname [path norm [info nameofexecutable]]]
    dict set config --lib-dir     [info library]

    dict set config --man-dir     [dict get $config --prefix]/man
    dict set config --html-dir    [dict get $config --prefix]/html

    dict set config --ignore-glob {
	*~ _FOSSIL_ .fslckout .fos .git .svn CVS .hg RCS SCCS
	*.bak *.bzr *.cdv *.pc _MTN _build _darcs _sgbak blib
	autom4te.cache cover_db ~.dep ~.dot ~.nib ~.plst
    }

    # Default file action: Do
    dict set config --dry 0

    # Default goals
    if {$tcl_platform(platform) eq "windows"} {
	dict set config @goals gui
    } else {
	dict set config @goals ghelp
    }
} ::kettle::option}

# # ## ### ##### ######## ############# #####################
return
