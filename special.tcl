# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Special commands outside of goal processing.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::special {
    namespace export setup doc-setup doc-config
    namespace ensemble create

    # TODO: Commands for manipulation/configuration of the documentation setup.
    # - License selection     (set == change)
    # - Requirement selection (add, remove)
    # - Keywords (subjects)   (add, remove)

    # Import the supporting utilities used here.
    namespace import ::kettle::path
    namespace import ::kettle::option
    namespace import ::kettle::io
    namespace import ::kettle::meta

    variable docbase   doc
    variable docconfig doc/parts/configuration.inc
}

# # ## ### ##### ######## ############# #####################
## API

proc ::kettle::special::setup {args} {
    # Generate a basic build.tcl file in the current working
    # directory.

    if {![llength $args]} {
	lappend args tcl
    }

    lappend lines "#!/usr/bin/env kettle"
    lappend lines "# -*- tcl -*-"
    foreach code $args {
	lappend lines [list kettle {*}$code]
    }
    path write build.tcl [join $lines \n]\n
    return
}

proc ::kettle::special::doc-setup {{pname {}}} {
    variable docbase
    set sources [pwd]

    if {$pname eq {}} {
	set pname [file tail $sources]
    }

    set pname  [string tolower $pname]
    set ptitle [string totitle $pname]

    # Generate a <docbase> directory in the source directory.

    io puts "Setting up documentation in $docbase"
    io puts "  Project $pname ($ptitle)"

    set dst [path norm $docbase]

    # 1. Fixed-text basics.

    set docsrc [path norm [option get @kettledir]/doc-parts]

    set origin $docsrc/guides
    path in $origin {
	path foreach-file $origin o {
	    set o [path strip $o $origin]
	    path copy-file $o $dst

	    if {[file extension $o] eq ".man"} {
		# Fix destination name, add project name.
		file rename $dst/$o $dst/${pname}_$o
	    }
	}
    }

    # 2. Rewrite the configuration file.
    EditConfig \
	project   $pname \
	ptitle    $ptitle \
	copyright [clock format [clock seconds] -format %Y]

    meta get-vc-information [pwd] m
    if {[dict get $m vc::system] ne "unknown"} {
	EditConfig vc_type [dict get $m vc::system]
    }

    # consolidate within meta, extend to git.
    if {[path find.fossil [pwd]] ne {}} {
	set remote [exec {*}[auto_execok fossil] remote]
	regsub {/[^@]*@} $remote {/} remote
	EditConfig repository $remote
    }

    # 3. Place standard license (BSD).
    # 4. Place standard requirement (Tcl 8.5).
    # TODO: Go through a temp file with proper name to insert without
    # endangering existing files.

    append dst /parts

    path in $docsrc/license {
	path copy-file bsd.inc $dst
	file rename $dst/bsd.inc $dst/license.inc
    }

    path in $docsrc/requirements {
	path copy-file tcl85.inc $dst
	file rename $dst/tcl85.inc $dst/rq_tcl.inc
    }

    io puts "!Attention"
    io puts "  You have to edit doc/parts/module.inc to suit"
    io puts "  (special copyrights, module description, common keywords, ...)"
    io puts "!Attention"

    # Show current configuration
    io puts ""
    io puts "Current configuration..."
    doc-config
    return
}

proc ::kettle::special::doc-config {args} {
    variable docconfig
    set config [path norm $docconfig]
    set data [Decode [path cat $config]]

    if {![llength $args]} {
	# show all
	unset config
	array set config $data
	parray config
	return
    }

    if {[llength $args] == 1} {
	# show specified key
	puts [dict get $data [lindex $args 0]]
	return
    }

    # change keys...
    path write $config [Encode [dict merge $data $args]]
    return
}

proc ::kettle::special::EditConfig {args} {
    variable docconfig
    set config [path norm $docconfig]
    path write-modify $config [list ::kettle::special::ChangeConfig $args]
    return
}

proc ::kettle::special::ChangeConfig {dict contents} {
    set contents [Decode $contents]
    set contents [dict merge $contents $dict]
    Encode $contents
}

proc ::kettle::special::Decode {contents} {
    set config {}
    foreach line [split [string trim $contents] \n] {
	lassign [string range $line 1 end-1] _ key value
	dict set config [string tolower $key] $value
    }
    return $config
}

proc ::kettle::special::Encode {config} {
    set lines {}
    foreach k [lsort -dict [dict keys $config]] {
	lappend lines "\[[list vset [string toupper $k] [dict get $config $k]]\]"
    }
    return [join $lines \n]
}

# # ## ### ##### ######## ############# #####################
return
