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
    namespace import ::kettle::cli

    variable docbase   doc
    variable cfgfile   doc/parts/configuration.inc
    variable kwfile    doc/parts/keywords.inc
    variable rqfile    doc/parts/requirements.inc
}

# # ## ### ##### ######## ############# #####################
## API

kettle cli extend {project setup} {
    section {Project Management}
    description {
	Generate a basic build control file in the current working
	directory. The arguments, if any, name the API commands
	to put into the file. Defaults to 'tcl'.
    }
    input args {
	The DSL commands to place into the generated file.
    } {
	optional ; list ; validate str ;# TODO: validate against available
	default tcl
    }
} ::kettle::special::Setup 

proc ::kettle::special::Setup {config} {
    set commands [$config @args]

    lappend lines "#!/usr/bin/env kettle"
    lappend lines "# -*- tcl -*-"
    lappend lines "# For kettle sources, documentation, etc. see"
    lappend lines "# - http://core.tcl.tk/akupries/kettle"
    lappend lines "# - http://chiselapp.com/user/andreas_kupries/repository/Kettle"
    lappend lines "package require kettle"

    foreach code $commands {
	lappend lines [list kettle {*}$code]
    }
    path write build.tcl [join $lines \n]\n
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project doc setup} {
    section {Project Management} Documentation
    description {
	Generates a basic documentation setup for the named
	project, in the current working directory. If the
	project is not named the last part of the directory
	name is used as default.

	Use 'doc configure', etc. to query and (re)configure
	other parts of the setup after the fact.
    }
    input project {
	The name of the project. Defaults to the name of
	the directory the project is in.
    } {
	optional
	validate str
	default [file tail [pwd]]
    }
} ::kettle::special::DocSetup

proc ::kettle::special::DocSetup {config} {
    variable docbase

    set project [$config @project]

    set pname  [string tolower $project]
    set ptitle [string totitle $project]

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
    DocConfigure \
	project   $pname \
	ptitle    $ptitle \
	copyright [clock format [clock seconds] -format %Y]

    meta get-vc-information [pwd] m
    if {[dict get $m vc::system] ne "unknown"} {
	DocConfigure vc_type [dict get $m vc::system]
    }

    # consolidate within meta, extend to git.
    if {[path find.fossil [pwd]] ne {}} {
	set remote [exec {*}[auto_execok fossil] remote]
	regsub {/[^@]*@} $remote {/} remote
	DocConfigure repository $remote
    }

    # 3. Place standard license (BSD).
    # 4. Place standard requirement (Tcl 8.5).
    # 5. Place standard requirement (Kettle build system).

    io puts ""
    io puts "Configurable parts"

    DocLicense bsd
    DocRequirements= tcl85 kettle

    # Show current configuration
    io puts ""
    io puts "Current configuration..."
    DocConfigure

    io puts ""
    io puts "Current keywords..."
    DocKeywords

    io puts ""
    io puts "Current requirements..."
    DocRequirements

    # Show current edit points
    io puts ""
    io puts "Files with places to edit (Marker @EDIT)"
    DocEditHooks

    io puts ""
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project doc list-edit-hooks} {
    section {Project Management} Documentation

    description {
	Show all places in the generated documentation where the user
	can and should edit it to suit the project.
    }
} ::kettle::special::DocEditHooks

proc ::kettle::special::DocEditHooks {{config {}}} {
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

# # ## ### ##### ######## ############# #####################

kettle cli extend {project doc configure} {
    section {Project Management} Documentation

    description {
	Query and change the configuration of the project found
	in the current working directory. Assumes a structure
	created by 'doc setup'.

	Without argument prints the whole configuration. With a
	single argument it prints the value of the so named
	configuration variable. With a list of keys and values
	it changes the configuration accordingly.
    }
    input args {
	The keys and values to set, or the key to query.
    } {
	optional ; list ; validate str
    }
} [lambda@ ::kettle::special config {
    set args [$config @args]
    # Note!
    # All execution paths hide 'license' from the user.
    # This key is handled by a separate set of commands.

    # No arguments. Print the entire configuration.
    if {![llength $args]} {
	array set configuration [DocConfigureGetAll]
	unset     configuration(license)
	parray    configuration
	return
    }

    # Single argument. Print the value for the specified key.
    if {[llength $args] == 1} {
	set key [lindex $args 0]
	if {$key eq "license"} {
	    return -code error -errorcode {KETTLE SPECIAL DOC CONFIGURE BAD KEY} \
		"Unknown configuration key \"$key\""
	}
	puts [DocConfigureGet $key]
	return
    }

    # Dictionary of arguments. Perform the assignments, changing the
    # configuration.
    catch { dict unset args license }
    DocConfigure $args
    return
}]

proc ::kettle::special::DocConfigure {assignments} {
    set data [LoadConfig]
    dict set data config \
	[EncodeConfig \
	     [dict merge \
		  [DecodeConfig [dict get $data config]] \
		  $assignments]]
    SaveConfig $data
    return
}

proc ::kettle::special::DocConfigureGetAll {} {
    # show all
    return [DecodeConfig [dict get [LoadConfig] config]]
}

proc ::kettle::special::DocConfigureGet {key} {
    # show specified key
    set config [DecodeConfig [dict get [LoadConfig] config]]
    if {![dict exists $config $key]} {
	return -code error -errorcode {KETTLE SPECIAL DOC CONFIGURE BAD KEY} \
	    "Unknown configuration key \"$key\""
    }
    return [dict get $config $key]
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project licenses} {
    section {Project Management} License

    description {
	List the available licenses we can apply to the project.
    }
} ::kettle::special::LicenseList

proc ::kettle::special::LicenseList {{config {}}} {
    foreach license [glob -directory [License] -tails *.inc] {
	set license [file rootname $license]
	io puts "  $license"
    }
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project license set} {
    section {Project Management} License

    description {
	Set the license to use for the project.
    }
    input license {
	The name of the license chosen for the project.
    } {
	validate str ;#TODO: validate against available licenses
    }
} ::kettle::special::LicenseSet

proc ::kettle::special::LicenseSet {config} {
    variable docbase

    set name [$config @license]

    io puts ""
    io puts "Configuring license ..."

    # TODO: Move this into a custom validation type.
    set src [License ${name}.inc]
    set dst [path norm $docbase/parts/license.inc]

    if {![file exists $src]} {
	io err {
	    io puts "  No file found for license: $name"
	}
	return
    }

    PlacePart $src $dst
    DocConfigure license $name
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project license show} {
    section {Project Management} License
    description {
	Show the license currently in use by the project.
    }
} ::kettle::special::LicenseShow

proc ::kettle::special::LicenseShow {config} {
    DocConfigureGet license
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project requirements available} {
    section {Project Management} Dependencies
    description {
	List the available text-blocks describing the requirements
	which can be apply to the project.
    }
} ::kettle::special::ReqAvailable

proc ::kettle::special::ReqAvailable {config} {
    foreach rq [lsort -dict [glob -directory [Require] -tails *.inc]] {
	set rq [file rootname $rq]
	io puts "  $rq"
    }
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project requirements used} {
    section {Project Management} Dependencies
    description {
	List the requirements currently applied to the project.
    }
} ::kettle::special::ReqUsed

proc ::kettle::special::ReqUsed {config} {
    set d [ReadRequirements]
    dict with d {} ; # header, config
    foreach rq $config {
	puts \t$rq
    }
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project requirements set} {
    section {Project Management} Dependencies
    description  {
	Set the requirements which apply to the project.
    }
    input args {
	The list of requirements to apply to the project,
	chosen from the available text-blocks.
    } {
	list
	validate str ;# TODO: validate against available blocks.
    }
} ::kettle::special::ReqSet

proc ::kettle::special::ReqSet {config} {
    set args [$config @args]

    variable docbase
    set d [ReadRequirements]
    dict set d config $args

    io puts ""
    io puts "Setting requirements ..."

    # TODO: Compare to the previous list of requirements and remove
    # the files for parts the user got rid of.

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

kettle cli extend {project subjects} {
    section {Project Management} Subjects
    description  {
	List the common keywords currently applied to the project.
    }
} ::kettle::special::SubjList

proc ::kettle::special::SubjList {config} {
    set d [ReadKeywords]
    dict with d {} ; # header, config
    foreach kw [lsort -dict $config] {
	puts \t$kw
    }
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project subject set} {
    section {Project Management} Subjects
    description {
	Set the keywords which apply to the project.
    }
    input args {
	The list of keywords to apply to the project.
	Can be empty.
    } {
	optional
	list
	validate str
    }
} ::kettle::special::SubjSet

proc ::kettle::special::SubjSet {config} {
    set args [$config @args]
    set d [ReadKeywords]
    dict set d config $args
    # Note: Backend handles removal of duplicates
    WriteKeywords $d
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project subject add} {
    section {Project Management} Subjects
    description {
	Add keywords to the project.
    }
    input args {
	The list of keywords to add to the project.
    } {
	list
	validate str
    }
} ::kettle::special::SubjAdd

proc ::kettle::special::SubjAdd {config} {
    set args [$config @args]
    set d [ReadKeywords]
    dict lappend d config {*}$args
    # Note: Backend handles removal of duplicates
    WriteKeywords $d
    return
}

# # ## ### ##### ######## ############# #####################

kettle cli extend {project subject remove} {
    section {Project Management} Subjects
    description {
	Remove keywords from the project.
    }
    input args {
	The list of keywords to remove from the project.
    } {
	list
	validate str
    }
} ::kettle::special::SubjRemove

proc ::kettle::special::SubjRemove {config} {
    set args [$config @args]
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
    # Rewrite the keyword list into a list of arguments lists.
    # Duplicates are removed as part of this process.

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
## Configuration data.

proc ::kettle::special::LoadConfig {} {
    variable cfgfile
    return [Decode [path cat [path norm $cfgfile]]]
}

proc ::kettle::special::SaveConfig {data} {
    variable cfgfile
    path write [path norm $cfgfile] [Encode $data vset]
}

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
## General data {en,de}coder
## - Line-based format
## - 1st line is a descriptive header, not data.
## - 1st and last character of data lines are non-data (brackets).
## - data is a list of words, 1st word is irrelevant.

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
