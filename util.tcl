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

proc ::kettle::util::libdir {} {
    global argv
    if {[llength $argv] && [file exists [set p [lindex $argv 0]]]} {
	set argv [lassign $argv _]
	log {	lib/ directory (User)    = $p}
    } else {
	set p [info library]
	log {	lib/ Directory (Default) = $p}
    }
    proc ::kettle::util::libdir {} [list return $p]
    return $p
}

proc ::kettle::util::bindir {} {
    set p [libdir]
    if {$p eq [info library]} {
	set p [file dirname [file dirname [file normalize [info nameofexecutable]/___]]]
	log {	bin/ Directory (Default) = $p}
    } else {
	set p [file dirname $p]/bin
	log {	bin/ directory (User)    = $p}
    }
    proc ::kettle::util::bindir {} [list return $p]
    return $p
}

proc ::kettle::util::mandir {} {
    set p [libdir]
    if {$p eq [info library]} {
	set p [file dirname [file dirname $p]]/man
	log {	man/ Directory (Default) = $p}
    } else {
	set p [file dirname $p]/man
	log {	man/ directory (User)    = $p}
    }
    proc ::kettle::util::mandir {} [list return $p]
    return $p
}

proc ::kettle::util::htmldir {} {
    set p [libdir]
    if {$p eq [info library]} {
	set p [file dirname [file dirname $p]]/html
	log {	html/ Directory (Default) = $p}
    } else {
	set p [file dirname $p]/html
	log {	html/ directory (User)    = $p}
    }
    proc ::kettle::util::htmldir {} [list return $p]
    return $p
}

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

# # ## ### ##### ######## ############# #####################
## Ready

namespace eval ::kettle::util {
    namespace import ::kettle::log

    namespace export {[a-z]*}
    namespace ensemble create
}

package provide kettle::util 0
return

# # ## ### ##### ######## ############# #####################
