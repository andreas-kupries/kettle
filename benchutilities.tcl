# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Benchmark Utilities.

namespace eval ::kb {
    namespace export {[a-z]*}
    namespace ensemble create

    # Directory the benchmark file is in.
    variable benchDirectory

    # Counter for 'bench_tmpfile'.
    variable uniqid 0

    # Global configuration settings for 'bench'.
    variable  config 
    array set config {
	ERRORS		1
	MATCH		{}
	RMATCH		{}
	FILES		{}
	ITERS		1000
    }

    # 'config' contents:
    #
    # - ERRORS  : Boolean flag. If set benchmark output mismatches are
    #             reported by throwing an error. Otherwise they are simply
    #             listed as BAD_RES. Default true. Can be set/reset via
    #             option -errors.
    #
    # - MATCH   : Match pattern, see -match, default empty, aka everything
    #             matches.
    #
    # - RMATCH  : Match pattern, see -rmatch, default empty, aka
    #             everything matches.
    #
    # - FILES   : List of benchmark files to run.
    #
    # - ITERS   : Number of iterations to run a benchmark body, default
    #             1000. Can be overridden by the individual benchmarks.
}

# # ## ### ##### ######## ############# #####################
## API. Use of files relative to the test directory.

proc ::kb::source {path} {
    variable benchDirectory
    uplevel 1 [list ::source [file join $benchDirectory $path]]
}

proc ::kb::find {pattern} {
    variable benchDirectory
    return [lsort -dict [glob -nocomplain -directory $benchDirectory $pattern]]
}

proc ::kb::source* {pattern} {
    foreach f [find $pattern] {
	uplevel 1 [list ::source $f]
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Use of packages. Support, and under profiling.

proc ::kb::check {name version} {
    if {[package vsatisfies [package provide $name] $version]} {
	puts "SYSTEM - $name [package present $name]"
	return
    }

    puts "    Aborting the benchmarks found in \"[file tail [info script]]\""
    puts "    Requiring at least $name $version, have [package present $name]."

    # This causes a 'return' in the calling scope.
    return -code return
}

proc ::kb::require {type name args} {
    variable tag
    try {
	package require $name {*}$args
    } on error {e o} {
	puts "    Aborting the benchmarks found in \"[file tail [info script]]\""
	puts "    Required package $name not found: $e"
	return -code return
    }

    puts "SYSTEM [dict get $tag $type] $name [package present $name]"
    return
}

proc ::kb::local {type name args} {
    variable tag
    # Specialized package require. It is forced to search (via
    # forget), and its search is restricted to the local installation,
    # via a custom unknown handler temporarily replacing the regular
    # functionality.

    set saved [package unknown]
    try {
	package unknown ::kb::PU
	package forget  $name
	package require $name {*}$args
    } on error {e o} {
	puts "    Aborting the benchmarks found in \"[file tail [info script]]\""
	puts "    Required local package $name not found: $e"
	return -code return
    } finally {
	package unknown $saved
    }

    puts "LOCAL  [dict get $tag $type] $name [package present $name]"
    return
}

proc ::kb::PU {name args} {
    global   auto_path
    variable localprefix

    set saved $auto_path
    set auto_path [list $localprefix/lib]

    # Direct call into package scan, ignore modules.
    tclPkgUnknown __ignored__

    set auto_path $saved
    return
}

namespace eval ::kb {
    variable tag {
	support   -
	benchmark %
    }
}

# # ## ### ##### ######## ############# #####################
## Benchmark API. Taken out of libbench, more package like.

#
# It claims all procedures starting with bench*
#

# bench_tmpfile --
#
#   Return a temp file name that can be modified at will
#
# Arguments:
#   None
#
# Results:
#   Returns file name
#
proc bench_tmpfile {} {
    variable ::kb::uniqid
    global tcl_platform env

    set base "tclbench[pid].[incr uniqid].dat"

    if {$tcl_platform(platform) eq "unix"} {
	return "/tmp/$base"
    } elseif {$tcl_platform(platform) eq "windows"} {
	return [file join $env(TEMP) $base]
    } else {
	return $base
    }
}

# bench_rm --
#
#   Remove a file silently (no complaining)
#
# Arguments:
#   args	Files to delete
#
# Results:
#   Returns nothing
#
proc bench_rm {args} {
    foreach file $args {
	catch {
	    file delete $file
	}
    }
    return
}

proc bench_puts {args} {
    kb::Note Feedback $args
    return
}

# # ## ### ##### ######## ############# #####################
## Helper code.





# # ## ### ##### ######## ############# #####################
return
