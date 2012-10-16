# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Path utility commands.

namespace eval ::kettle::path {
    namespace export {[a-z]*}
    namespace ensemble create

    # unable to import kettle::option, circular dependency
    namespace import ::kettle::io
    namespace import ::kettle::status
}

# # ## ### ##### ######## ############# #####################
## API commands.

proc ::kettle::path::norm {path} {
    # full path normalization
    return [file dirname [file normalize $path/__]]
}

proc ::kettle::path::strip {path prefix} {
    return [file join \
		{*}[lrange \
			[file split [norm $path]] \
			[llength [file split [norm $prefix]]] \
			end]]
}

proc ::kettle::path::sourcedir {{path {}}} {
    return [norm [file join [kettle option get @srcdir] $path]]
}

proc ::kettle::path::script {} {
    return [norm [kettle option get @srcscript]]
}

proc ::kettle::path::libdir {{path {}}} {
    return [norm [file join [kettle option get --lib-dir] $path]]
}

proc ::kettle::path::bindir {{path {}}} {
    return [norm [file join [kettle option get --bin-dir] $path]]
}

proc ::kettle::path::incdir {{path {}}} {
    return [norm [file join [kettle option get --include-dir] $path]]
}

proc ::kettle::path::mandir {{path {}}} {
    return [norm [file join [kettle option get --man-dir] $path]]
}

proc ::kettle::path::htmldir {{path {}}} {
    return [norm [file join [kettle option get --html-dir] $path]]
}

proc ::kettle::path::set-executable {path} {
    io trace {	!chmod ugo+x   $path}
    catch {
	file attributes $path -permissions ugo+x
    }
    return
}

proc ::kettle::path::grep {pattern data} {
    return [lsearch -all -inline -glob [split $data \n] $pattern]
}

proc ::kettle::path::rgrep {pattern data} {
    return [lsearch -all -inline -regexp [split $data \n] $pattern]
}

proc ::kettle::path::fixhashbang {file shell} {
    set in [open $file r]
    gets $in line
    if {![string match "#!*tclsh*" $line]} {
	return -code error "No tclsh #! in $file"
    }

    io trace {	!fix hash-bang $shell}

    set   out [open ${file}.[pid] w]
    io puts $out "#!/usr/bin/env [norm $shell]"

    fconfigure $in  -translation binary -encoding binary
    fconfigure $out -translation binary -encoding binary
    fcopy $in $out
    close $in
    close $out

    file rename -force ${file}.[pid] $file
    return
}

proc ::kettle::path::tcl-package-file {file} {
    set contents   [cat $file]
    set provisions [grep {*package provide *} $contents]
    if {![llength $provisions]} {
	return 0
    }

    io trace {    Testing: $file}

    foreach line $provisions {
	io trace {        Candidate |$line|}
	if {[catch {
	    lassign $line cmd method pn pv
	}]} {
	    io trace {        * Not a list}
	    continue
	}
	if {$cmd ne "package"} {
	    io trace {        * $cmd: Not a 'package' command}
	    continue
	}
	if {$method ne "provide"} {
	    io trace {        * $method: Not a 'package provide' command}
	    continue
	}
	if {[catch {package vcompare $pv 0}]} {
	    io trace {        * $pkgver: Not a version number}
	    continue
	}
	if {[llength [rgrep {package\s+require\s+critcl} $contents]]} {
	    io trace {        * critcl required: Not pure Tcl}
	    continue
	}

	io trace {    Accepted: $pn $pv @ $file}

	lappend files $file
	# Look for referenced dependent files.
	foreach line [grep {* @owns: *} $contents] {
	    if {![regexp {#\s+@owns:\s+(.*)$} $line -> path]} continue
	    lappend files $path
	}

	# For 'scan'.
	kettle option set @predicate [list $files $pn $pv]
	return 1
    }

    # No candidate satisfactory.
    return 0
}

proc ::kettle::path::critcl3-package-file {file} {
    set contents   [cat $file]
    set provisions [grep {*package provide *} $contents]
    if {![llength $provisions]} {
	return 0
    }

    io trace {    Testing: $file}

    foreach line $provisions {
	io trace {        Candidate |$line|}
	if {[catch {
	    lassign $line cmd method pn pv
	}]} {
	    io trace {        * Not a list}
	    continue
	}
	if {$cmd ne "package"} {
	    io trace {        * $cmd: Not a 'package' command}
	    continue
	}
	if {$method ne "provide"} {
	    io trace {        * $method: Not a 'package provide' command}
	    continue
	}
	if {[catch {package vcompare $pv 0}]} {
	    io trace {        * $pkgver: Not a version number}
	    continue
	}

	# Nearly accepted. Now check if this file asks for critcl.

	if {![llength [rgrep {package\s+require\s+critcl\s+3} $contents]]} {
	    io trace {        * critcl 3: Not required}
	    continue
	}

	io trace {    Accepted: $pn $pv @ $file}

	# For 'scan'.
	kettle option set @predicate [list $file $pn $pv]
	return 1
    }

    # No candidate satisfactory.
    return 0
}

proc ::kettle::path::doctools-file {path} {
    set test [cathead $path 1024 -translation binary]
    # anti marker
    if {[regexp -- {--- !doctools ---}            $test]} { return 0 }
    if {[regexp -- "!tcl\.tk//DSL doctools//EN//" $test]} { return 0 }
    # marker
    if {[regexp "\\\[manpage_begin "             $test]} { return 1 }
    if {[regexp -- {--- doctools ---}            $test]} { return 1 }
    if {[regexp -- "tcl\.tk//DSL doctools//EN//" $test]} { return 1 }
    # no usable marker
    return 0
}

proc ::kettle::path::diagram-file {path} {
    set test [cathead $path 1024 -translation binary]
    # marker
    if {[regexp {tcl.tk//DSL diagram//EN//1.0} $test]} { return 1 }
    # no usable marker
    return 0
}

proc ::kettle::path::tcltest-file {path} {
    set test [cathead $path 1024 -translation binary]
    # marker
    if {[regexp {tcl.tk//DSL tcltest//EN//} $test]} { return 1 }
    # no usable marker
    return 0
}

proc ::kettle::path::bench-file {path} {
    set test [cathead $path 1024 -translation binary]
    # marker
    if {[regexp {tcl.tk//DSL tclbench//EN//} $test]} { return 1 }
    # no usable marker
    return 0
}

proc ::kettle::path::kettle-build-file {path} {
    set test [cathead $path 100 -translation binary]
    # marker (no anti-markers)
    if {[regexp {kettle -f} $test]} { return 1 }
    return 0
}

proc ::kettle::path::foreach-file {path pv script} {
    upvar 1 $pv thepath

    set ex [kettle option get --ignore-glob]

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

proc ::kettle::path::scan {label root predicate} {
    set nroot [sourcedir $root]

    io trace {}
    io trace {SCAN $label @ $root/}

    if {![file exists $nroot]} {
	io trace {  NOT FOUND}
	return -code return
    }

    set result {}
    foreach-file $nroot path {
	set spath [strip $path $nroot]
	try {
	    kettle option unset @predicate
	    if {![uplevel 1 [list {*}$predicate $path]]} continue

	    io trace {    Accepted: $spath}

	    if {[kettle option exists @predicate]} {
		lappend result {*}[kettle option get @predicate]
	    } else {
		lappend result $spath
	    }
	} on error {e o} {
	    io err { io puts "    Skipped: $path @ $e" }
	} finally {
	    kettle option unset @predicate
	}
    }

    if {![llength $result]} { return -code return }

    return [list $nroot $result]
}

proc ::kettle::path::tmpfile {{prefix tmp_}} {
    global tcl_platform
    return .kettle_$prefix[pid]_[clock seconds]_[clock milliseconds]_[info hostname]_$tcl_platform(user)
}

proc ::kettle::path::cat {path args} {
    set c [open $path r]
    if {[llength $args]} { fconfigure $c {*}$args }
    set contents [read $c]
    close $c
    return $contents
}

proc ::kettle::path::cathead {path n args} {
    set c [open $path r]
    if {[llength $args]} { fconfigure $c {*}$args }
    set contents [read $c]
    close $c
    return $contents
}

proc ::kettle::path::write {path contents args} {
    set c [open $path w]
    if {[llength $args]} { fconfigure $c {*}$args }
    ::puts -nonewline $c $contents
    close $c
    return
}

proc ::kettle::path::copy-file {src dstdir} {
    # copy single file into destination _directory_
    # Fails on an existing file.

    io puts -nonewline "\tInstalling file [file tail $src]: "
    if {[catch {
	if {![kettle option get --dry]} {
	    file copy $src $dstdir/[file tail $src]
	}
    } msg]} {
	io err { io puts "FAIL ($msg)" }
	status fail
	return 0
    } else {
	io ok { io puts OK }
	return 1
    }
}

proc ::kettle::path::copy-files {dstdir args} {
    # copy multiple files into a destination _directory_
    # Fails on an existing file.
    foreach src $args {
	if {![copy-file $src $dstdir]} { return 0 }
    }
    return 1
}

proc ::kettle::path::remove-path {path} {
    # General uninstallation of a file or directory.

    io puts -nonewline "\tUninstalling ${path}: "
    if {[catch {
	if {![kettle option get --dry]} {
	file delete -force $path
	}
    } msg]} {
	io err { io puts "FAIL ($msg)" }
	status fail
	return 0
    } else {
	io ok { io puts OK }
	return 1
    }
}

proc ::kettle::path::remove-paths {args} {
    # General uninstallation of multiple files.
    foreach path $args {
	if {![remove-path $path]} { return 0 }
    }
    return 1
}

proc ::kettle::path::install-application {src dstdir} {
    # install single-file application into destination _directory_.
    # a previously existing file is moved out of the way.

    set fname [file tail $src]

    io puts "Installing application \"$fname\""
    io puts "    Into $dstdir"

    if {![kettle option get --dry]} {
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

    if {![kettle option get --dry]} {
	set-executable $dstdir/$fname
    }
    return
}

proc ::kettle::path::install-script {src dstdir shell} {
    # install single-file script application into destination _directory_.
    # a previously existing file is moved out of the way.

    set fname [file tail $src]

    io puts "Installing script \"$fname\""
    io puts "    Into $dstdir"

    # Save existing file, if any.
    if {![kettle option get --dry]} {
	file mkdir $dstdir
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

    if {![kettle option get --dry]} {
	fixhashbang    $dstdir/$fname $shell
	set-executable $dstdir/$fname
    }
    return
}

proc ::kettle::path::install-file-group {label dstdir args} {
    # Install multiple files into a destination directory.
    # The destination is created to hold the files. The files
    # are strongly coupled, i.e. belong together.

    io puts "Installing $label"
    io puts "    Into $dstdir"

    set new ${dstdir}-new
    set old ${dstdir}-old

    if {![kettle option get --dry]} {
	# Clean temporary destination. Remove left-overs from previous runs.
	file delete -force $new
	file mkdir         $new
    }

    if {![copy-files $new {*}$args]} {
	file delete -force $new
	return
    }

    # Now shuffle old and new things around to put the new into place.
    io puts -nonewline {    Commmit: }
    if {[catch {
	if {![kettle option get --dry]} {
	    file delete -force $old
	    catch { file rename $dstdir $old }
	    file rename -force $new $dstdir
	    file delete -force $old
	}
    } msg]} {
	io err { io puts "FAIL ($msg)" }
	status fail
    } else {
	io ok { io puts OK }
    }
    return
}

proc ::kettle::path::install-file-set {label dstdir args} {
    # Install multiple files into a destination directory.
    # The destination has to exist. The files in the set
    # are only loosely coupled. Example: manpages.

    io puts "Installing $label"
    io puts "    Into $dstdir"

    ## Consider removal of existing files ...
    ## Except, for manpages we want to be informed of clashes.
    ## for others it might make sense ...

    copy-files $dstdir {*}$args
    return
}

proc ::kettle::path::uninstall-application {src dstdir} {
    set fname [file tail $src]

    io puts "Uninstall application \"$fname\""
    io puts "    From $dstdir"

    remove-path $dstdir/$fname
    return
}

proc ::kettle::path::uninstall-file-group {label dstdir} {
    io puts "Uninstalling $label"
    io puts "    From $dstdir"

    remove-path $dstdir
    return
}

proc ::kettle::path::uninstall-file-set {label dstdir args} {
    # Install multiple files into a destination directory.
    # The destination has to exist. The files in the set
    # are only loosely coupled. Example: manpages.

    io puts "Uninstalling $label"
    io puts "    From $dstdir"

    ## Consider removal of existing files ...
    ## Except, for manpages we want to be informed of clashes.
    ## for others it might make sense ...

    foreach f $args {
	if {![remove-path $dstdir/$f]} return
    }
    return
}

proc ::kettle::path::exec {args} {
    pipe line {
	io puts $line
    } {*}$args
    return
}

proc ::kettle::path::pipe {lv script args} {
    upvar 1 $lv line
    set stderr [tmpfile pipe_stderr_]

    io trace {  PIPE: $args}

    if {[kettle option get --dry]} return

    set err {}
    set pipe [open "|$args 2> $stderr" r]

    try {
	while {![eof $pipe]} {
	    if {[gets $pipe line] < 0} continue
	    try {
		uplevel 1 $script
	    } trap {KETTLE} {e o} {
		# Rethrow internal signals.
		# No report, not a true error.
		return {*}$o $e
	    } on error {e o} {
		io err { io puts $e }
		break
	    }
	}
    } finally {
	try {
	    close $pipe
	} on error {e o} {
	    io err { io puts $e }
	}

	set err [cat $stderr]
	file delete $stderr
    }

    if {$err eq {}} return
    io err { io puts $err }
    return
}

proc ::kettle::path::in {path script} {
    set here [pwd]
    try {
	cd $path
	uplevel 1 $script
    } finally {
	cd $here
    }
}

# # ## ### ##### ######## ############# #####################
## Internal

proc ::kettle::path::Ignore {patterns path} {
    set path [file tail $path]
    foreach p $patterns {
	if {[string match $p $path]} { return 1 }
    }
    return 0
}

# # ## ### ##### ######## ############# #####################
return
