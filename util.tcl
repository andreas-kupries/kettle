## util.tcl --
# # ## ### ##### ######## ############# #####################
#
#	kettle utilities for recipes.
#
# Copyright (c) 2012 Andreas Kupries

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require  kettle ; # core

# # ## ### ##### ######## ############# #####################
## State, Initialization

namespace eval ::kettle::util {}

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::util::set-executable {path} {
    log {	!chmod ugo+x   $path}
    catch { file attributes $path -permissions ugo+x }
    return
}

proc ::kettle::util::grep {pattern file} {
    set lines [split [read [set chan [open $file r]]] \n]
    close $chan
    return [lsearch -all -inline -glob $lines $pattern]
}

proc ::kettle::util::fixhashbang {file shell} {
    set in [open $file r]
    gets $in line
    if {![string match "#!*tclsh*" $line]} {
	return -code error "No tclsh #! in $file"
    }

    log {	!fix hash-bang $shell}

    set   out [open ${file}.[pid] w]
    puts $out "#!/usr/bin/env $shell"

    fconfigure $in  -translation binary -encoding binary
    fconfigure $out -translation binary -encoding binary
    fcopy $in $out
    close $in
    close $out

    file rename -force ${file}.[pid] $file
    return
}

proc ::kettle::util::provides {file} {
    set provisions [grep {*package provide*} $file] ; # (*)
    if {![llength $provisions]} {
	return -code error {No package provided}
    }
    # Note: Using index 'end' here ensures that we are not using the
    # grep pattern above (*) as result for this package itself.
    set pkgname [lindex $provisions end 2]
    set pkgver  [lindex $provisions end 3]
    log {	Package: ($pkgname) ($pkgver)}
    return [list $pkgname $pkgver]
}

proc ::kettle::util::docfile {path} {
    set c [open $path r]
    fconfigure $c -translation binary -buffersize 1024 -buffering full
    set test [read $c 1024]
    close $c
    if {([regexp "\\\[manpage_begin " $test] &&
	 !([regexp -- {--- !doctools ---} $test] || [regexp -- "!tcl\.tk//DSL doctools//EN//" $test])) ||
	  ([regexp -- {--- doctools ---} $test]  || [regexp -- "tcl\.tk//DSL doctools//EN//" $test])} {
	return 1
    } 
    return 0
}

proc ::kettle::util::diafile {path} {
    set c [open $path r]
    fconfigure $c -translation binary -buffersize 1024 -buffering full
    set test [read $c 1024]
    close $c
    if {([regexp {tcl.tk//DSL diagram//EN//1.0} $test]} {
	return 1
    } 
    return 0
}

proc ::kettle::util::foreach-file {path pv script} {
    upvar 1 $pv thepath

    set known {}
    lappend waiting $path
    while {[llength $waiting]} {
	set pending $waiting
	set waiting {}
	set at 0
	while {$at < [llength $pending]} {
	    set current [lindex $pending $at]
	    incr at

	    # Do not follow into parent.
	    if {[string match *.. $current]} continue

	    # Ignore what we have visited already.
	    set c [file dirname [file normalize $current/___]]
	    if {[dict exists $known $c]} continue
	    dict set known $c .

	    # Expand directories.
	    if {[file isdirectory $c]} {
		lappend waiting {*}[lsort -unique [glob -directory $c * .*]]
		continue
	    }

	    # Handle files as per the user's will.
	    set thepath $current
	    switch -exact -- [catch { uplevel 1 $script } result] {
		0 - 4 {
		    # ok, continue - nothing
		}
		2 {
		    # return, abort, rethrow
		    return -code return
		}
		3 {
		    # break, abort
		    return
		}
		1 - default {
		    # error, any thing else - rethrow
		    return -code error $result
		}
	    }
	}
    }
    return
}

proc ::kettle::util::install_group {label dst args} {
    # General installation of multiple files into a destination
    # directory.

    # args = files and directories to copy into group.

    set new ${dst}-new
    set old ${dst}-old

    puts -nonewline "${label}: "

    # Setup of destination, separate directory.
    file delete -force $new
    file mkdir         $new

    # Fill destination
    foreach path $args {
	puts -nonewline *
	file copy -force $path $new
    }

    # Swizzle old and new install (old might not exist).

    file delete -force $old
    catch { file rename $dst $old }
    file rename -force $new $dst
    file delete -force $old

    puts -nonewline { }
    ok { puts OK }
    return
}


proc ::kettle::util::install_path {label dst src {postscript {}}} {
    # General installation of a single file into a destination
    # path.

    set new ${dst}-new
    set old ${dst}-old

    puts -nonewline "${label}: "

    # Setup of destination.
    file mkdir [file dirname $dst]
    file delete -force $new

    # Copy to destination
    puts -nonewline *
    file copy -force $src $new

    # User specified customizations, if any.
    uplevel 1 $postscript

    # Swizzle old and new install (old might not exist).

    file delete -force $old
    catch { file rename $dst $old }
    file rename -force $new $dst
    file delete -force $old

    puts -nonewline { }
    ok { puts OK }
    return
}

proc ::kettle::util::drop_path {label dst} {
    # General uninstallation of a destination directory.

    puts -nonewline "${label}: "

    file delete -force $dst

    ok { puts OK }
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

namespace eval ::kettle::util {
    namespace import ::kettle::log
    namespace import ::kettle::puts
    namespace import ::kettle::ok

    namespace export {[a-z]*}
    namespace ensemble create
}

package provide kettle::util 0
return

# # ## ### ##### ######## ############# #####################
