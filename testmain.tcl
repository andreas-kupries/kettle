# -*- tcl -*- Copyright (c) 2012-2018 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Test Application (Entry point into .test files)
##
## Syntax: <localprefix> <testfile> <mode> <options>
##         kt::localprefix kt::testfile kt::mode kt::argv
## mode in {scan, run}

# Kettle is designed to accomodate 8.5+
package require Tcl 8.5

# Accomodate use of wish as test shell.
catch {wm withdraw .}

# # ## ### ##### ######## ############# #####################
## Get the kettle information before loading tcltest.
## Everything goes into the ::kt namespace to separate things from
## tcltest and others (the testsuite).

namespace eval ::kt {}

set argv [lassign $argv kt::localprefix kt::testfile kt::mode]

# Check for valgrind
set valgrind 0
set pos [lsearch -exact $argv --valgrind]
if {$pos >= 0} {
    set argv [lreplace $argv $pos $pos]
    set valgrind 1
}

set kt::main $argv0
set kt::argv $argv
set argv0 $kt::testfile

#puts X_k[pid]\t[join $::auto_path \nX_k[pid]\t]

# # ## ### ##### ######## ############# #####################
## Import tcltest. This will process the remaining argv elements.
## All kettle argv elements must be processed before this point.

# Force full verbosity.
lappend argv -verbose bpstenl

package require tcltest
# We can assume tcltest 2 or higher, due to our assumption of Tcl 8.5
# or higher.

# For scan mode forcibly disable execution of tests. We cannot use the
# option -skip for this as it will also prevent output for the
# matching tests, i.e. all of them, and for the scan we want to know
# the test names. Therefore we get our desired behaviour by hacking
# the tcltest internals to suit.
if {$kt::mode eq "scan"} {
    proc tcltest::test {name args} {
	puts "---- $name DECL"
	return
    }
}

# The next command enables the execution of 'tk' constrained tests, if
# Tk is present (for example when this code is run run by 'wish').

catch {
    package require Tk
    wm withdraw .
}

# # ## ### ##### ######## ############# #####################
## Management utilities for communication with the 'test' recipe
## support code in our caller.

if {($kt::mode eq "scan") ||
    ($kt::mode eq "sub")} {
    # Prevent reporting in scan and sub modes.
    proc kt::Note {args} {}
} else {
    proc kt::Note {k v} {
	puts  stdout [list @@ $k $v]
	flush stdout
	return
    }
}

proc kt::Now {} {return [clock seconds]}

if {$kt::mode eq "scan"} {
    # In scan mode we must not report, even from a sub-shell.
    proc kt::Report {} {}
} elseif {$kt::mode eq "sub"} {
    # In a subshell the results have to be passed up the chain to the
    # caller for integration. See kt::sub below.
    proc kt::Report {} {
	variable ::tcltest::numTests
	variable ::tcltest::skippedBecause
	variable ::tcltest::createdNewFiles
	tcltest::makeFile \
	    [list tcltest::ReportedFromSlave \
		 $numTests(Total) $numTests(Passed) $numTests(Skipped) \
		 $numTests(Failed) [array get skippedBecause] \
		 [array get createdNewFiles]]\n \
	    report
	return
    }
}

# Place a test script into a sub-shell.
proc kt::sub {name script args} {
    # Build test file
    set data ""
    # Import the specified context (variables by name, and assignments).
    foreach v $args {
	if {[regexp {^([^=]*)=(.*)$} $v -> var val]} {
	    append data [list set $var $val]\n
	} else {
	    upvar 1 $v val
	    append data [list set $v $val]\n
	}
    }
    # Add the user's script, and report always, even in the presence of errors.
    append data "try \{\n"
    append data $script
    append data "\n\} finally \{\n"
    # See kt::Report above.
    append data kt::Report\n
    append data "\}\n"
    set path [tcltest::makeFile $data $name]
    # Run the file like we are run (same context and arguments, except
    # for mode.
    set mode sub
    if {$kt::mode eq "scan"} { set mode scan }

    if {$::valgrind} {
	lappend cmd [auto_execok valgrind]
    }
    lappend cmd [info nameofexecutable] $kt::main $kt::localprefix \
	$path $mode {*}$kt::argv
    if {$::valgrind} {
	lappend cmd --valgrind
    }
    try {
	exec 2>@ stderr >@ stdout {*}$cmd
	# Integrate the child's report into this process' statistics
	eval [viewFile report]
	tcltest::removeFile report
    } finally {
	tcltest::removeFile $path
    }
    return
}

# Ensure a fully normalized absolute path to the test suite location.
set ::tcltest::testsDirectory \
    [file dirname [file normalize $::tcltest::testsDirectory]/___]

# # ## ### ##### ######## ############# #####################
## Start reporting, the environment in which the tests are run.

puts stdout ""
kt::Note Host       [info hostname]
kt::Note Platform   $tcl_platform(os)-$tcl_platform(osVersion)-$tcl_platform(machine)
kt::Note TestDir    $::tcltest::testsDirectory
kt::Note LocalDir   $::kt::localprefix
kt::Note TestCWD    [pwd]
kt::Note Shell      [info nameofexecutable]
kt::Note Tcl        [info patchlevel]

# Host  => Platform | Identity of the Test environment.
# Shell => Tcl      |
# CWD               | Identity of the package under test.

if {[llength $::tcltest::skip]}       {kt::Note SkipTests  $::tcltest::skip}
if {[llength $::tcltest::match]}      {kt::Note MatchTests $::tcltest::match}
if {[llength $::tcltest::skipFiles]}  {kt::Note SkipFiles  $::tcltest::skipFiles}
if {[llength $::tcltest::matchFiles]} {kt::Note MatchFiles $::tcltest::matchFiles}

# # ## ### ##### ######## ############# #####################
## Import kettle provided utility commands (kt:: namespace)
## the testsuite can use. And a try/finally for ourselves.

source [file dirname [file normalize [info script]]]/try.tcl
source [file dirname [file normalize [info script]]]/testutilities.tcl

namespace import ::tcltest::*

# # ## ### ##### ######## ############# #####################
## Run the testsuite.

# Disable the use of exit inside of tcltest::cleanupTests.
rename exit __exit
proc   exit {args} {}

kt::Note Testsuite $kt::testfile
kt::Note Start [kt::Now]

if {[catch {
    source $kt::testfile
} msg]} {
    # Transmit stack trace in capturable format.
    puts stdout "@+"
    puts stdout @|[join [split $errorInfo \n] "\n@|"]
    puts stdout "@-"
}

kt::Note End [kt::Now]
puts ""

#::tcltest::cleanupTests 1
# # ## ### ##### ######## ############# #####################
# FRINK: nocheck
# Use of 'exit' ensures proper termination of the test system when
# driven by a 'wish' instead of a 'tclsh'. Otherwise 'wish' would
# enter its regular event loop and no tests would complete.
__exit
