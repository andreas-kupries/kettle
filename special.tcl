# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Special commands outside of goal processing.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definitions, other utilities)

namespace eval ::kettle::special {
    # Import the supporting utilities used here.
    namespace import ::kettle::path
    namespace import ::kettle::option
    namespace import ::kettle::io
    namespace import ::kettle::meta

    variable docbase   doc
    variable cfgfile   doc/parts/configuration.inc
    variable kwfile    doc/parts/keywords.inc
    variable rqfile    doc/parts/requirements.inc
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

# # ## ### ##### ######## ############# #####################

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

# # ## ### ##### ######## ############# #####################

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
    doc-config \
	project   $pname \
	ptitle    $ptitle \
	copyright [clock format [clock seconds] -format %Y]

    meta get-vc-information [pwd] m
    if {[dict get $m vc::system] ne "unknown"} {
	doc-config vc_type [dict get $m vc::system]
    }

    # consolidate within meta, extend to git.
    if {[path find.fossil [pwd]] ne {}} {
	set remote [exec {*}[auto_execok fossil] remote]
	regsub {/[^@]*@} $remote {/} remote
	doc-config repository $remote
    }

    # 3. Place standard license (BSD).
    # 4. Place standard requirement (Tcl 8.5).
    # 5. Place standard requirement (Kettle build system).

    io puts ""
    io puts "Configurable parts"

    license bsd
    requirements= tcl85 kettle

    # Show current configuration
    io puts ""
    io puts "Current configuration..."
    doc-config

    io puts ""
    io puts "Current keywords..."
    keywords

    io puts ""
    io puts "Current requirements..."
    requirements

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
    variable cfgfile
    set theconfig [path norm $cfgfile]
    set data [Decode [path cat $theconfig]]

    if {![llength $args]} {
	# show all
	array set config [DecodeConfig [dict get $data config]]
	parray config
	return
    }

    if {[llength $args] == 1} {
	# show specified key
	puts [dict get [DecodeConfig [dict get $data config]] [lindex $args 0]]
	return
    }

    # change keys...
    dict set data config \
	[EncodeConfig \
	     [dict merge \
		  [DecodeConfig [dict get $data config]] \
		  $args]]
    path write $theconfig [Encode $data vset]
    return
}

# # ## ### ##### ######## ############# #####################

::kettle::special::Def licenses? {} {
    List the licenses we can apply to the project.
} {
    foreach license [glob -directory [License] -tails *.inc] {
	set license [file rootname $license]
	io puts "  $license"
    }
    return
}

::kettle::special::Def license {{name {}}} {
    Set or query the license to use for the project.
} {
    variable docbase

    if {$name eq {}} {
	doc-config license
	return
    }

    io puts ""
    io puts "Configuring license ..."

    set src [License ${name}.inc]
    set dst [path norm $docbase/parts/license.inc]

    if {![file exists $src]} {
	io err {
	    io puts "  No file found for license: $name"
	}
	return
    }

    PlacePart $src $dst
    doc-config license $name
    return
}

# # ## ### ##### ######## ############# #####################

::kettle::special::Def requirements? {} {
    List the requirements text-blocks we can apply to the project.
} {
    foreach rq [lsort -dict [glob -directory [Require] -tails *.inc]] {
	set rq [file rootname $rq]
	io puts "  $rq"
    }
    return
}

::kettle::special::Def requirements {} {
    List the requirements currently applied to the project.
} {
    set d [ReadRequirements]
    dict with d {} ; # header, config
    foreach rq $config {
	puts \t$rq
    }
    return
}

::kettle::special::Def requirements= {args} {
    Set the requirements which apply to the project.
} {
    variable docbase

    set d [ReadRequirements]
    dict set d config $args

    io puts ""
    io puts "Setting requirements ..."

    foreach rq $args {
	set src [Require $rq.inc]
	set dst [path norm $docbase/parts/rq_${rq}.inc]

	if {![file exists $src]} {
	    io err {
		io puts "  No file found for requirement: $rq"
	    }
	    return
	}
	PlacePart $src $dst
    }
    WriteRequirements $d
    return
}

# # ## ### ##### ######## ############# #####################

::kettle::special::Def keywords {} {
    List the common keywords currently applied to the project.
} {
    set d [ReadKeywords]
    dict with d {} ; # header, config
    foreach kw [lsort -dict $config] {
	puts \t$kw
    }
    return
}

::kettle::special::Def keywords= {args} {
    Set the common keywords which apply to the project.
} {
    set d [ReadKeywords]
    dict set d config $args
    WriteKeywords $d
    return
}

::kettle::special::Def keywords+ {args} {
    Add common keywords to the project.
} {
    set d [ReadKeywords]
    dict lappend d config {*}$args
    WriteKeywords $d
    return
}

::kettle::special::Def keywords- {args} {
    Remove common keywords from the project.
} {
    set d [ReadKeywords]
    set k [dict get $d config]

    foreach remove $args {
	set pos [lsearch -exact $k $remove]
	if {$pos < 0} continue
	set k [lreplace $k $pos $pos]
    }

    dict set d config $k
    WriteKeywords $d
    return
}

# # ## ### ##### ######## ############# #####################
## API support commands.

proc ::kettle::special::ReadKeywords {} {
    variable kwfile
    set data [Decode [path cat [path norm $kwfile]]]

    # config is list of argument-lists.
    # An argument list is list of keywords.
    # Rewrite to single list of keywords.

    set new {}
    foreach words [dict get $data config] {
	lappend new {*}$words
    }
    dict set data config [lsort -unique [lsort -dict $new]]
    return $data
}

proc ::kettle::special::WriteKeywords {data} {
    variable kwfile
    # Rewrite keyword list into list of arguments lists.

    set new {}
    foreach k [lsort -unique [lsort -dict [dict get $data config]]] {
	lappend new [list $k]
    }
    dict set data config $new
    path write [path norm $kwfile] [Encode $data keywords]
    return
}

proc ::kettle::special::ReadRequirements {} {
    variable rqfile
    set data [Decode [path cat [path norm $rqfile]]]

    # config is list of argument-lists.
    # An argument list is single-element list of include file.
    # Rewrite to single list of requirements

    set new {}
    foreach words [dict get $data config] {
	lappend new [string range [file rootname [lindex $words 0]] 3 end]
    }
    dict set data config $new
    return $data
}

proc ::kettle::special::WriteRequirements {data} {
    variable rqfile
    # Rewrite requirement list into list of arguments lists.

    set new {}
    foreach k [dict get $data config] {
	lappend new [list rq_${k}.inc]
    }
    dict set data config $new
    path write [path norm $rqfile] [Encode $data include]
    return
}

# # ## ### ##### ######## ############# #####################

proc ::kettle::special::License {{which {}}} {
    return [file join [Base license] $which]
}

proc ::kettle::special::Require {{which {}}} {
    return [file join [Base requirements] $which]
}

proc ::kettle::special::Base {{which {}}} {
    return [file join [path norm [option get @kettledir]/doc-parts] $which]
}

# # ## ### ##### ######## ############# #####################

proc ::kettle::special::DecodeConfig {assignments} {
    set config {}
    foreach item $assignments {
	lassign $item k v
	dict set config [string tolower $k] $v
    }
    return $config
}

proc ::kettle::special::EncodeConfig {config} {
    set new {}
    foreach {k v} $config {
	lappend new [list [string toupper $k] $v]
    }
    return [lsort -unique [lsort -dict $new]]
}

# # ## ### ##### ######## ############# #####################

proc ::kettle::special::Decode {contents} {
    set header {}
    set config {}
    set first 1
    foreach line [split [string trim $contents] \n] {
	if {$first} {
	    set header $line
	    set first 0
	    continue
	}
	set words [lrange [string range $line 1 end-1] 1 end]
	lappend config $words
    }
    return [dict create header $header config $config]
}

proc ::kettle::special::Encode {dict cmd} {
    dict with dict {} ;# -> header, config
    set lines [list $header]
    foreach item $config {
	set item  "\[$cmd $item\]"
	lappend lines $item
    }
    return [join $lines \n]\n
}

# # ## ### ##### ######## ############# #####################

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
	    file delete $dstdir/$dstfile
	    path copy-file $dstfile $dstdir
	}
    } finally {
	file delete -force $tmpdir/$dstfile $tmpdir
    }
    return
}

# # ## ### ##### ######## ############# #####################
return
