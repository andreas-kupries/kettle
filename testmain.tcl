# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Test Application (Entry point into .test files)
##
## argv = testfile (tcltest arguments ...)

# Kettle is designed to accomodate 8.5+
package require Tcl 8.5

# Accomodate use of wish as test shell.
catch {wm withdraw .}

# # ## ### ##### ######## ############# #####################
## Get the kettle information before loading tcltest.
## Everything goes into the ::kt namespace to separate things from
## tcltest and others (the testsuite).

namespace eval ::kt {}

set argv  [lassign $argv kt::localprefix kt::testfile]
set argv0 $kt::testfile

# # ## ### ##### ######## ############# #####################
## Import tcltest. This will process the remaining argv elements.
## All kettle argv elements must be processed before this point.

# Force full verbosity.
lappend argv -verbose bpstenl

package require    tcltest
namespace import ::tcltest::*

# The next command enables the execution of 'tk' constrained tests, if
# Tk is present (for example when this code is run run by 'wish').

catch {
    package require Tk
    wm withdraw .
}

# # ## ### ##### ######## ############# #####################
## Management utilities for communication with the 'test' recipe
## support code in our caller.

proc kt::Note {k v} {
    puts  stdout [list @@ $k $v]
    flush stdout
    return
}

proc kt::Now {} {return [clock seconds]}

# Ensure an fully normalized absolute path to the test suite location.
set ::tcltest::testsDirectory \
    [file dirname [file normalize $::tcltest::testsDirectory]/___]

# # ## ### ##### ######## ############# #####################
## Start reporting, the environment in which the tests are run.

puts stdout ""
kt::Note Host       [info hostname]
kt::Note Platform   $tcl_platform(os)-$tcl_platform(osVersion)-$tcl_platform(machine)
kt::Note TestDir    $::tcltest::testsDirectory
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
## the testsuite can use.

source [file dirname [file normalize [info script]]]/testutilities.tcl

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
