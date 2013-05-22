# -*- tcl -*- Copyright (c) 2013 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## TEApot meta data parsing/processing.

# # ## ### ##### ######## ############# #####################
## Export (internals - )

namespace eval ::kettle::meta {
    namespace export {[a-z]*}
    namespace ensemble create

    namespace import ::kettle::io
    namespace import ::kettle::path
    namespace import ::kettle::mdref
}

# # ## ### ##### ######## ############# #####################
## State

namespace eval ::kettle::meta {
    variable md {} ; # dict (type --> (name --> meta data))
}

# # ## ### ##### ######## ############# #####################
## API.

# Files:
# (1) Having marker (see path teapot-file)
# (3) inlined in .tcl file of a package.

# If data for a package P is found in several locations the data from
# the higher numbers has precedence. During installation of a package P
# a teapot.txt is generated, holding the data for P in external format.

proc ::kettle::meta::scan {} {
    # Heuristic search for meta data in the directory containing tcl
    # packages, in separate files. See (1).

    Init

    # Heuristic search for package meta data.
    lassign [path scan \
		 {teapot metadata}\
		 [path sourcedir] \
		 {path teapot-file}] \
	root files

    foreach f $files {
	read-external $f
    }
    return
}

proc ::kettle::meta::read-external {file} {
    #puts E|$file
    set contents [path cat $file]
    Parse $contents
    return
}

proc ::kettle::meta::read-internal {file} {
    #puts I|$file
    Parse [GetInternal [path cat $file]]
    return
}

proc ::kettle::meta::write {dst type name ver} {
    path write $dst [join [Assemble $name $ver $type [Get $type $name]] \n]
    return $dst
}

# # ## ### ##### ######## ############# #####################
## Internals

proc ::kettle::meta::Get {type name} {
    variable md
    if {![dict exists $md $type $name]} {
	set m {}
    } else {
	set m [dict get $md $type $name]
	dict unset m name
	dict unset m version
	dict unset m entity
    }

    dict set m build::date \
	[clock format [clock seconds] -format {%Y-%m-%d}]

    return $m
}

proc ::kettle::meta::GetInternal {str} {
    set collect 0
    set meta    {}

    foreach line [split $str \n] {
	# Ignore everything until the beginning of the meta data
	# block.

	if {[regexp "^# @@ Meta Begin" $line]} {
	    io trace "META $line"
	    set collect 1
	    continue 
	}

	if {!$collect} continue

	io trace "META $line"

	# Stop collecting meta data when we reach the end of the
	# block.

	if {[regexp "^# @@ Meta End" $line]} {
	    break
	}

	# We are inside of the Meta data block. Strip the comment
	# prefix from the line, i.e. transform the embedded meta
	# information back into the regular form.

	regsub "^\#\[ \t\]*" $line {} line
	lappend meta $line
    }

    return [join $meta \n]
}

proc ::kettle::meta::Parse {str} {
    # str is expected to be in the 'external' teapot format.

    #puts P|$str|

    set i [interp create -safe]

    # Action for data collection ...
    interp alias $i Meta {} ::kettle::meta::M

    # Actions for entity collection (new sections) ...

    foreach entity {
	package application
    } {
	# Not handled: documentation profile redirect
	set cmd [string totitle $entity]
	interp alias $i $cmd {} ::kettle::meta::E $entity
    }

    try {
	interp eval $i $str
	SaveLast
	Normalize
	Validate
    } on error {e o} {
	set msg [::string map {
	    {::kettle::meta::} {}
	} $e]
	io err { io puts "Bad meta data syntax: $msg" }
	#puts $::errorInfo
    } finally {
	interp delete $i
    }
    return
}

proc ::kettle::meta::E {type name version} {
    SaveLast

    variable md
    variable ctype   $type
    variable cname   $name
    variable current {}

    io trace {New $ctype : "$cname" $version}

    dict set current name    $name
    dict set current version $version
    dict set current entity  $type
    return
}

proc ::kettle::meta::M {key args} {
    variable cname
    variable current

    # Ignore everything before the start of the first entity.
    if {$cname eq ""} return

    io trace {M $key = ($args)}
    dict lappend current $key {*}$args
    return
}

proc ::kettle::meta::Init {} {
    variable md      {} ;# dict: package --> meta data
    variable current {} ;# dict: key --> value
    variable cname   {} ;# name of current entity.
    variable ctype   {} ;# type of current entity.
    return
}

proc ::kettle::meta::SaveLast {} {
    variable md
    variable cname
    variable ctype
    variable current

    if {$cname eq {}} return

    dict set md $ctype $cname $current

    set ctype   {}
    set cname   {}
    set current {}
    return
}

proc ::kettle::meta::Normalize {} {
    variable md
    if {![dict size $md]} return

    dict for {type data} $md {
	dict for {name meta} $data {

	    # Special knowledge about dependencies, remove duplicates,
	    # redundancies. Ditto for platform, in an effort to handle
	    # crooked input better.

	    if {[dict exists $meta platform]} {
		dict set meta platform \
		    [lsort -uniq [dict get $meta platform]]
	    }

	    foreach what {require recommend} {
		if {![dict exists $meta $what]} continue
		dict set meta $what \
		    [mdref normalize [dict get $meta $what]]
	    }

	    dict set data $name $meta
	}

	dict set md $type $data
    }
    return
}

proc ::kettle::meta::Validate {} {
    variable md
    set errors 0

    if {![dict size $md]} {
	io err { io puts {No entities found} }
	return 0
    }

    dict for {type data} $md {
	dict for {name meta} $data {
	    set e [dict get $meta entity]
	    set n [dict get $meta name]
	    set v [dict get $meta version]

	    set prefix "Bad meta data for $e $n $v:"

	    if {![dict exists $meta platform]} {
		io err { io puts "$prefix Incomplete, no platform specified" }
		dict unset meta $name
		incr errors
	    } elseif {[llength [dict get $meta platform]] > 1} {
		io err { io puts "$prefix Multi-platform archives are not acceptable." }
		dict unset meta $name
		incr errors
	    }

	    foreach {what label} {
		require   requirement
		recommend recommendation
	    } {
		if {![dict exists $meta $what]} continue

		# Special knowledge about dependencies, check their
		# syntax.

		foreach ref [dict get $meta $what] {
		    if {![mdref valid $ref message]} {
			io err { io puts "$prefix Bad reference syntax in $label \"$ref\": $message" }
			dict unset meta $name
			incr errors
		    }
		}
	    }

	    dict set data $name $meta
	}

	dict set md $type $data
    }

    if {$errors} { return 0 }
    return 1
}

proc ::kettle::meta::Assemble {name ver type meta} {
    array set   md $meta
    array unset md __* ; # Squash everything internal

    set  maxl [MaxLength md]
    set  margin 67 ; # 72 -5 (Meta )
    incr margin -$maxl

    lappend lines [list [string totitle $type] $name $ver]

    foreach k [lsort [array names md]] {
	set sk [string tolower $k]

	switch -exact -- $sk {
	    require -
	    recommend {
		# Bug 72969. Do not sort dependencies, order may be
		# important during setup.
		foreach e [mdref normalize $md($k)] {
		    # Convert internal list form of requirements into
		    # Tcl form for easier use by humans.
		    set e [mdref 2tcl $e]
		    lappend lines [ALine $k $maxl [list $e]]
		}
		continue
	    }
	}

	# Semi paragraph-formatting of everything else across multiple
	# lines.

	if {![llength $md($k)]} {
	    lappend lines [ALine $k $maxl ""]
	    continue
	}

	set buf ""
	foreach e $md($k) {
	    if {![llength $buf]} {
		lappend buf $e
		continue
	    }
	    if {([string length $buf] + [string length $e] + 1) > $margin} {
		lappend lines [ALine $k $maxl $buf]
		set buf {}
	    }
	    lappend buf $e
	}
	if {[llength $buf]} {
	    lappend lines [ALine $k $maxl $buf]
	}
    }

    lappend lines {} ; # Forces a \n at the end of the block when joining the lines.
    return $lines

}

proc ::kettle::meta::ALine {k maxl v} {
    return "Meta [format "%-*s" $maxl [list $k]] $v"
}

proc ::kettle::meta::MaxLength {mv} {
    upvar 1 $mv md

    set maxl 0
    foreach k [array names md] {
	set l [string length [list $k]]
	if {$l > $maxl} {set maxl $l}
    }

    return $maxl
}

# # ## ### ##### ######## ############# #####################
## Initialization

# # ## ### ##### ######## ############# #####################
return

