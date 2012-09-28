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
## @owns: io.tcl
## @owns: status.tcl
## @owns: recipes.tcl
## @owns: path.tcl
## @owns: options.tcl
## @owns: gui.tcl
## @owns: standard.tcl
## @owns: tclapp.tcl
## @owns: tcl.tcl
## @owns: doc.tcl
## @owns: figures.tcl
## @owns: app.tcl

::apply {{selfdir} {
    # # ## ### ##### ######## ############# ##################### Foundation
    source $selfdir/io.tcl       ; # Message output support.
    source $selfdir/status.tcl   ; # General goal status.
    source $selfdir/recipes.tcl  ; # Recipe management.
    source $selfdir/path.tcl     ; # General path utilities
    source $selfdir/options.tcl  ; # Option management.
    source $selfdir/gui.tcl      ; # GUI support.
    source $selfdir/standard.tcl ; # Standard recipes.
    # # ## ### ##### ######## ############# ##################### DSL
    source $selfdir/tclapp.tcl   ; # tcl script applications
    source $selfdir/tcl.tcl      ; # tcl packages
    source $selfdir/doc.tcl      ; # documentation (doctools)
    source $selfdir/figures.tcl  ; # figures       (diagram)
    # # ## ### ##### ######## ############# ##################### Application
    source $selfdir/app.tcl      ; # Application core.
    # # ## ### ##### ######## ############# #####################
}} [file dirname [file normalize [info script]]]

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle 0
return

# # ## ### ##### ######## ############# #####################
