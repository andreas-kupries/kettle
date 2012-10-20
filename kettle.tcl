# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Kettle package

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
namespace eval ::kettle {}

# # ## ### ##### ######## ############# #####################
## Export

namespace eval ::kettle {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## @owns: app.tcl
## @owns: benchmarks.tcl
## @owns: critcl.tcl
## @owns: depend.tcl
## @owns: doc.tcl
## @owns: figures.tcl
## @owns: gui.tcl
## @owns: invoke.tcl
## @owns: io.tcl
## @owns: lambda.tcl
## @owns: options.tcl
## @owns: ovalidate.tcl
## @owns: path.tcl
## @owns: recipes.tcl
## @owns: standard.tcl
## @owns: status.tcl
## @owns: tcl.tcl
## @owns: tclapp.tcl
## @owns: testsuite.tcl
## @owns: tool.tcl
## @owns: try.tcl

## These two files are not sourced as part of the kettle application.
##
# The first is the main entry point for the 'test' recipe, i.e. the
# application running a specific .test file. It is used to communicate
# build configuration data into the test environment.
##
# The other provides lots of utilities to make writing tests easier.

## @owns: testmain.tcl
## @owns: testutilities.tcl

::apply {{selfdir} {
    # # ## ### ##### ######## ############# ##################### Foundation
    source $selfdir/lambda.tcl     ; # Nicer way of writing apply
    source $selfdir/try.tcl        ; # try/finally in Tcl, snarfed from 8.6
    source $selfdir/io.tcl         ; # Message output support.
    source $selfdir/status.tcl     ; # General goal status.
    source $selfdir/recipes.tcl    ; # Recipe management.
    source $selfdir/path.tcl       ; # General path utilities
    source $selfdir/ovalidate.tcl  ; # Option management. Validation sub layer.
    source $selfdir/options.tcl    ; # Option management.
    source $selfdir/invoke.tcl     ; # Goal recursion via sub-processes.
    source $selfdir/tool.tcl       ; # Manage tool requirements.
    source $selfdir/gui.tcl        ; # GUI support.
    source $selfdir/standard.tcl   ; # Standard recipes.
    # # ## ### ##### ######## ############# ##################### DSL
    source $selfdir/depend.tcl     ; # dependency setup.
    source $selfdir/tclapp.tcl     ; # tcl script applications
    source $selfdir/tcl.tcl        ; # tcl packages
    source $selfdir/critcl.tcl     ; # critcl v3 packages
    source $selfdir/doc.tcl        ; # documentation (doctools)
    source $selfdir/figures.tcl    ; # figures       (diagram)
    source $selfdir/testsuite.tcl  ; # testsuite     (tcltest)
    source $selfdir/benchmarks.tcl ; # benchmarks    (tclbench)
    # # ## ### ##### ######## ############# ##################### Application
    source $selfdir/app.tcl        ; # Application core.
    # # ## ### ##### ######## ############# #####################
    kettle::option::set @kettledir $selfdir
}} [file dirname [file normalize [info script]]]

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle 0
return

# # ## ### ##### ######## ############# #####################
