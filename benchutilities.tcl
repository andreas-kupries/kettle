# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Benchmark Utilities.

namespace eval ::kb {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## API. Use of files relative to the test directory.

proc ::kb::source {path} {
    variable ::tcltest::testsDirectory
    uplevel 1 [list ::source [file join $testsDirectory $path]]
}

proc ::kb::find {pattern} {
    return [lsort -dict [glob -nocomplain -directory $::tcltest::testsDirectory $pattern]]
}

proc ::kb::source* {pattern} {
    foreach f [find $pattern] {
	uplevel 1 [list ::source $f]
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Use of packages. Support, and under test.

proc ::kb::check {name version} {
    if {[package vsatisfies [package provide $name] $version]} {
	puts "SYSTEM - $name [package present $name]"
	return
    }

    puts "    Aborting the tests found in \"[file tail [info script]]\""
    puts "    Requiring at least $name $version, have [package present $name]."

    # This causes a 'return' in the calling scope.
    return -code return
}

proc ::kb::require {type name args} {
    variable tag
    try {
	package require $name {*}$args
    } on error {e o} {
	puts "    Aborting the tests found in \"[file tail [info script]]\""
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
	puts "    Aborting the tests found in \"[file tail [info script]]\""
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

namespace eval ::kt {
    variable tag {
	support -
	testing %
    }
}

# # ## ### ##### ######## ############# #####################
return
