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
    return [lsearch -all -inline -glob [split [cat $file] \n] $pattern]
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
    set test [cathead $path 1024 -translation binary]
    if {([regexp "\\\[manpage_begin " $test] &&
	 !([regexp -- {--- !doctools ---} $test] || [regexp -- "!tcl\.tk//DSL doctools//EN//" $test])) ||
	  ([regexp -- {--- doctools ---} $test]  || [regexp -- "tcl\.tk//DSL doctools//EN//" $test])} {
	return 1
    } 
    return 0
}

proc ::kettle::util::diafile {path} {
    set test [cathead $path 1024 -translation binary]
    if {([regexp {tcl.tk//DSL diagram//EN//1.0} $test]} {
	return 1
    } 
    return 0
}

proc ::kettle::util::foreach-file {path pv script} {
    ## TODO ## Exclusion patterns! Standard, and user.

    upvar 1 $pv thepath

    set ex [kettle option-get --ignore-glob]

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

	    # Ignore non-development files.
	    if {[Ignore $ex $c]} continue

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

proc ::kettle::util::Ignore {patterns path} {
    set path [file tail $path]
    foreach p $patterns {
	if {[string match $p $path]} { return 1 }
    }
    return 0
}

proc ::kettle::util::tmpfile {{prefix kettle_util_}} {
    global tcl_platform
    return $prefix[pid]_[clock seconds]_[clock milliseconds]_[info hostname]_$tcl_platform(user)
}

proc ::kettle::util::cat {path args} {
    set c [open $path r]
    if {[llength $args]} { fconfigure $c {*}$args }
    set contents [read $c]
    close $c
    return $contents
}

proc ::kettle::util::cathead {path n args} {
    set c [open $path r]
    if {[llength $args]} { fconfigure $c {*}$args }
    set contents [read $c]
    close $c
    return $contents
}

proc ::kettle::util::write {path contents args} {
    set c [open $path w]
    if {[llength $args]} { fconfigure $c {*}$args }
    ::puts -nonewline $c $contents
    close $c
    return
}

proc ::kettle::util::copy-file {src dstdir} {
    # copy single file into destination _directory_
    # Fails on an existing file.
    kettle status-check

    puts -nonewline "\tInstalling file [file tail $src]: "
    if {[catch {
	if {![kettle option-get --dry]} {
	    file copy $src $dstdir/[file tail $src]
	}
    } msg]} {
	err { puts "FAIL ($msg)" }
	kettle status-fail
	return 0
    } else {
	ok { puts OK }
	return 1
    }
}

proc ::kettle::util::copy-files {dstdir args} {
    # copy multiple files into a destination _directory_
    # Fails on an existing file.
    foreach src $args {
	if {![copy-file $src $dstdir]} { return 0 }
    }
    return 1
}

proc ::kettle::util::remove-path {path} {
    # General uninstallation of a file or directory.

    kettle status-check

    puts -nonewline "\tUninstalling ${path}: "
    if {[catch {
	if {![kettle option-get --dry]} {
	file delete -force $path
	}
    } msg]} {
	err { puts "FAIL ($msg)" }
	kettle status-fail
	return 0
    } else {
	ok { puts OK }
	return 1
    }
}

proc ::kettle::util::remove-paths {args} {
    # General uninstallation of multiple files.
    foreach path $args {
	if {![remove-path $path]} { return 0 }
    }
    return 1
}

proc ::kettle::util::install-application {src dstdir} {
    # install single-file application into destination _directory_.
    # a previously existing file is moved out of the way.
    kettle status-check

    set fname [file tail $src]

    puts "Installing application \"$fname\""
    puts "    Into $dstdir"

    if {![kettle option-get --dry]} {
	# Save existing file, if any.
	file delete -force $dstdir/${fname}.old
	catch {
	    file rename $dstdir/${fname} $dstdir/${fname}.old
	}
    }

    if {![copy-file $src $dstdir]} {
	# Failed, restore previous, if any.
	catch {
	    file rename $dstdir/${fname}.old $dstdir/${fname}
	}
    }

    if {![kettle option-get --dry]} {
	set-executable $dstdir/$fname
    }
    return
}

proc ::kettle::util::install-script {src dstdir shell} {
    # install single-file script application into destination _directory_.
    # a previously existing file is moved out of the way.
    kettle status-check

    set fname [file tail $src]

    puts "Installing script \"$fname\""
    puts "    Into $dstdir"

    # Save existing file, if any.
    if {![kettle option-get --dry]} {
	file delete -force $dstdir/${fname}.old
	catch {
	    file rename $dstdir/${fname} $dstdir/${fname}.old
	}
    }

    if {![copy-file $src $dstdir]} {
	# Failed, restore previous, if any.
	catch {
	    file rename $dstdir/${fname}.old $dstdir/${fname}
	}
    }

    if {![kettle option-get --dry]} {
	fixhashbang    $dstdir/$fname $shell
	set-executable $dstdir/$fname
    }
    return
}

proc ::kettle::util::install-file-group {label dstdir args} {
    # Install multiple files into a destination directory.
    # The destination is created to hold the files. The files
    # are strongly coupled, i.e. belong together.
    kettle status-check

    puts "Installing $label"
    puts "    Into $dstdir"

    set new ${dstdir}-new
    set old ${dstdir}-old

    if {![kettle option-get --dry]} {
	# Clean temporary destination. Remove left-overs from previous runs.
	file delete -force $new
	file mkdir         $new
    }

    if {![copy-files $new {*}$args]} {
	file delete -force $new
	return
    }

    # Now shuffle old and new things around to put the new into place.
    puts -nonewline {    Commmit: }
    if {[catch {
	if {![kettle option-get --dry]} {
	    file delete -force $old
	    catch { file rename $dstdir $old }
	    file rename -force $new $dstdir
	    file delete -force $old
	}
    } msg]} {
	err { puts "FAIL ($msg)" }
	kettle status-fail
    } else {
	ok { puts OK }
    }
    return
}

proc ::kettle::util::install-file-set {label dstdir args} {
    # Install multiple files into a destination directory.
    # The destination has to exist. The files in the set
    # are only loosely coupled. Example: manpages.

    kettle status-check

    puts "Installing $label"
    puts "    Into $dstdir"

    ## Consider removal of existing files ...
    ## Except, for manpages we want to be informed of clashes.
    ## for others it might make sense ...

    copy-files $dstdir {*}$args
    return
}

proc ::kettle::util::uninstall-application {src dstdir} {
    kettle status-check

    set fname [file tail $src]

    puts "Uninstall application \"$fname\""
    puts "    From $dstdir"

    remove-path $dstdir/$fname
    return
}

proc ::kettle::util::uninstall-file-group {label dstdir} {
    kettle status-check

    puts "Uninstalling $label"
    puts "    From $dstdir"

    remove-path $dstdir
    return
}

proc ::kettle::util::uninstall-file-set {label dstdir args} {
    # Install multiple files into a destination directory.
    # The destination has to exist. The files in the set
    # are only loosely coupled. Example: manpages.

    kettle status-check

    puts "Uninstalling $label"
    puts "    From $dstdir"

    ## Consider removal of existing files ...
    ## Except, for manpages we want to be informed of clashes.
    ## for others it might make sense ...

    foreach f $args {
	if {![remove-path $dstdir/$f]} return
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

namespace eval ::kettle::util {
    namespace import ::kettle::log
    namespace import ::kettle::puts
    namespace import ::kettle::ok
    namespace import ::kettle::err

    namespace export {[a-z]*}
    namespace ensemble create
}

package provide kettle::util 0
return

# # ## ### ##### ######## ############# #####################
