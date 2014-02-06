## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Help - TCL format. Not available by default.
## Require this package before creation a commander, so that the
## mdr::help heuristics see and automatically integrate the format.

# @@ Meta Begin
# Package cmdr::help::tcl 1.0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Formatting help as TCL data structure (nested dict/list).
# Meta description Formatting help as TCL data structure (nested dict/list).
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# Meta require {cmdr::help 1}
# Meta require {cmdr::util 1}
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require debug
package require debug::caller
package require cmdr::help 1
package require cmdr::util 1

# # ## ### ##### ######## ############# #####################

debug define cmdr/help/tcl
debug level  cmdr/help/tcl
debug prefix cmdr/help/tcl {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Definition

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::help::format {
    namespace export tcl
    namespace ensemble create

    namespace import ::cmdr::help::query
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::tcl {root width help} {
    debug.cmdr/help/tcl {}
    # help = dict (name -> command)

    # Step 1. Command mapping.
    set commands {}
    dict for {cmd desc} $help {
	lappend commands $cmd [TCL $desc]
    }

    # Step 2. Section Tree. This is very similar to
    # cmdr::help::format::by-category, and re-uses its frontend helper
    # commands.

    lassign [SectionTree $help 0] subc cmds
    foreach c [SectionOrder $root $subc] {
	lappend sections [TCL::acategory [::list $c] $cmds $subc]
    }

    return [dict create \
		commands $commands \
		sections $sections]
}

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::help::format::TCL {}

proc ::cmdr::help::format::TCL::acategory {path cmds subc} {
    set name [lindex $path end]

    # With struct::list map we could then also re-use alist.
    set commands {}
    foreach def [lsort -dict -unique [dict get $cmds $path]] {
	lappend commands [lindex $def 0]
    }

    set sections {}
    if {[dict exists $subc $path]} {
	# Add the sub-categories, if any.
	foreach c [lsort -dict -unique [dict get $subc $path]] {
	    lappend sections [acategory [linsert $path end $c] $cmds $subc]
	}
    }

    return [dict create \
		name     $name \
		commands $commands \
		sections $sections]
}

proc ::cmdr::help::format::TCL {command} {
    # Data structure: see config.tcl,  method 'help'.
    # Data structure: see private.tcl, method 'help'.

    dict with command {}
    # -> action, desc, options, arguments, parameters, states, sections

    lappend dict action      $action
    lappend dict arguments   $arguments
    lappend dict description [TCL::astring $desc]
    lappend dict opt2para    [::cmdr util dictsort $opt2para]
    lappend dict options     [::cmdr util dictsort $options]
    lappend dict parameters  [TCL::parameters $parameters]
    lappend dict sections    $sections
    lappend dict states      $states
    
    return $dict
}

proc ::cmdr::help::format::TCL::parameters {parameters} {
    set dict {}
    foreach {name def} [::cmdr util dictsort $parameters] {
	set tmp {}
	foreach {xname xdef} [::cmdr util dictsort $def] {
	    switch -glob -- $xname {
		cmdline -
		defered -
		documented -
		interactive -
		isbool -
		list -
		ordered -
		presence -
		required -
		@bool {
		    # normalize to boolean
		    set value [expr {!!$xdef}]
		}
		threshold {
		    # null|integer
		    set value [expr {($xdef eq {}) ? "null" : $xdef}]
		}
		code -
		default -
		description -
		prompt -
		type -
		label -
		@string {
		    set value [astring $xdef]
		}
		generator -
		validator -
		@cmdprefix { 
		    set value $xdef
		}
		flags -
		@dict {
		    set value [::cmdr util dictsort $xdef]
		}
		* {
		    error "Unknown key \"$xname\", do not know how to format"
		    #lappend tmp $xname [astring $xdef]
		}
	    }
	    lappend tmp $xname $value
	}
	lappend dict $name $tmp
    }
    return $dict
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::TCL::astring {string} {
    regsub -all -- {[ \n\t]+} $string { } string
    return [string trim $string]
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::help::tcl 1.0
