# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Special commands outside of goal processing.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::special {
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
    variable help      {}
}

# # ## ### ##### ######## ############# #####################
## Command definition with help.

proc ::kettle::special::Def {name alist helptext body} {
    variable help 
    dict set help @$name [list $alist $helptext]
    proc $name $alist $body

    namespace export $name
    namespace ensemble create
    return
}

# # ## ### ##### ######## ############# #####################
## API

::kettle::special::Def help {args} {
    Show help for all or just the named special commands.
} {
    variable help
    # No arguments, show help for all.
    if {![llength $args]} {
	foreach cmd [lsort -dict [dict keys $help]] {
	    lappend args $cmd
	}
    }

    foreach cmd $args {
	if {![dict exists $help $cmd]} {
	    io err {
		io puts "No help available for unknown command $cmd"
	    }
	} else {
	    lassign	[dict get $help $cmd] alist text
	    io puts "    [list $cmd $alist]\n\t[join [split $text \n] \n\t]"
	}
    }
    return
}

::kettle::special::Def setup {args} {
    Generate a basic build.tcl file in the current working
    directory. The arguments, if any, name the API commands
    to put into the file. Defaults to 'tcl'.
} {
    if {![llength $args]} {
	lappend args tcl
    }

    lappend lines "#!/usr/bin/env kettle"
    lappend lines "# -*- tcl -*-"
    lappend lines "package require kettle"
    foreach code $args {
	lappend lines [list kettle {*}$code]
    }
    path write build.tcl [join $lines \n]\n
    return
}

::kettle::special::Def doc-setup {{pname {}}} {
    Generates a basic documentation setup for the named
    project, in the current working directory. If the
    project is not named the last part of the directory
    name is used as default.

    Use @doc-config, etc. to query and (re)configure other
    parts of the setup after the fact.
} {
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
    # 5. Place standard requirement (Kettle build system).

    io puts ""
    io puts "Configurable parts"
    append dst /parts
    PlacePart $docsrc/license/bsd.inc         $dst/license.inc
    PlacePart $docsrc/requirements/tcl85.inc  $dst/rq_tcl85.inc
    PlacePart $docsrc/requirements/kettle.inc $dst/rq_kettle.inc

    # Show current configuration
    io puts ""
    io puts "Current configuration..."
    doc-config

    # Show current edit points
    io puts ""
    io puts "Files with places to edit (Marker @EDIT)"
    doc-edit-hooks

    io puts ""
    return
}

::kettle::special::Def doc-edit-hooks {} {
    Show all places in the generated documentation where the user
    can and should edit it to suit the project.
} {
    variable docbase
    set d [path norm $docbase]
    set first 1

    path foreach-file $d path {
	if {![llength [path grep {*@EDIT*} [split [path cat $path] \n]]]} continue
	if {$first} { io puts "" }
	set first 0
	io puts \tdoc/[path strip $path $d]
    }
    return
}

::kettle::special::Def doc-config {args} {
    Query and change the configuration of the documentation
    setup in the current working directory. Assumes a structure
    created by @doc-setup.

    Without argument prints the whole configuration. With a
    single argument it prints the value of the so named
    configuration variable. With a list of keys and values
    it changes the configuration accordingly.
} {
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

proc ::kettle::special::PlacePart {src dst} {
    set dstfile [file tail    $dst]
    set dstdir  [file dirname $dst]

    set slabel [file join {*}[lrange [file split $src] end-1 end]]

    io puts "    Placing $slabel ..."

    try {
	set tmpdir [path tmpfile placepart_]
	file mkdir    $tmpdir
	path ensure-cleanup $tmpdir

	file copy $src $tmpdir/$dstfile

	path in $tmpdir {
	    path copy-file $dstfile $dstdir
	}
    } finally {
	file delete -force $tmpdir/$dstfile $tmpdir
    }
    return
}

# # ## ### ##### ######## ############# #####################
return
