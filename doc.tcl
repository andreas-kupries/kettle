# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle tcllib/doctools documentation files

namespace eval ::kettle { namespace export doc }

kettle option set --doc-destination embedded

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::doc-destination {dstdir} {
    # NOTE: Both absolute paths and paths outside of the source
    # directory have sensible use-cases, hence my choice to not reject
    # them here.
    #
    # (1) The package in question may be part of a larger structure,
    # with a consolidated hierarchy for doc results
    #
    # (2) The user may wish to redirect the generated documenation
    # somewhere else.

    option set --doc-destination $dstdir
    return
}

proc ::kettle::doc {{docsrcdir doc}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::doc args {}

    # Heuristic search for figures
    figures $docsrcdir/figures

    set root [path sourcedir $docsrcdir]

    io trace {}
    io trace {SCAN tcllib/doctools @ $docsrcdir/}

    if {![file exists $root]} {
	io trace {  NOT FOUND}
	return
    }

    # Heuristic search for documentation files.
    set manpages {}
    path foreach-file $root path {
	if {[catch {
	    path doctools-file $path
	} adoc]} {
	    set path [file join {*}[lrange [file split $path] $n end]] 
	    err { puts "    Skipped: $docsrcdir/$path @ $adoc" }
	    continue
	}
	if {!$adoc} continue

	set spath [path strip $path $root]

	io trace {    Accepted: $docsrcdir/$spath}
	lappend manpages $spath
    }

    if {![llength $manpages]} return

    set dd      [path sourcedir [option get --doc-destination]]
    set mansrc  $dd/man/files
    set htmlsrc $dd/www

    set mandst  [path mandir  mann]
    set htmldst [path htmldir [file tail [path sourcedir]]]

    recipe define doc {
	(Re)generate the documentation embedded in the repository.
    } {root dst} {

	set here [pwd]

	cd $root

	puts "Removing old documentation..."
	file delete -force $dst

	file mkdir $dst/man
	file mkdir $dst/www

	## TODO ## Put the exec calls into a utility command which
	## ---- ## ensures proper output to the gui as well.

	puts "Generating man pages..."
	exec 2>@ stderr >@ stdout dtplite -ext n -o $dst/man nroff .
	# Note: Might be better to run them separately.
	# Note @: Or we shuffle the results a bit more in the post processing stage.

	puts "Generating 1st html..."
	exec 2>@ stderr >@ stdout dtplite -merge -o $dst/www html .
	puts "Generating 2nd html, resolving cross-references..."
	exec 2>@ stderr >@ stdout dtplite -merge -o $dst/www html .

	# Remove some of the generated files, consider them transient.
	cd  $dst/man ; file delete -force .idxdoc .tocdoc
	cd  ../www   ; file delete -force .idxdoc .tocdoc

	cd $here
    } $root $dd

    recipe define install-doc-manpages {
	Install manpages
    } {src dst} {
	path install-file-set \
	    "manpages" \
	    $dst {*}[glob -directory $src *.n]
	return
    } $mansrc $mandst

    recipe define install-doc-html {
	Install HTML documentation
    } {src dst} {
	path install-file-group \
	    "HTML documentation" \
	    $dst {*}[glob -directory $src *]
	return
    } $htmlsrc $htmldst

    recipe define drop-doc-manpages {
	Uninstall manpages
    } {src dst} {
	path uninstall-file-set \
	    "manpages" \
	    $dst {*}[glob -directory $src -tails *.n]
	return
    } $mansrc $mandst

    recipe define drop-doc-html {
	Uninstall HTML documentation
    } {dst} {
	path uninstall-file-group \
	    "HTML documentation" \
	    $dst
    } $htmldst

    recipe parent install-doc-html     install-doc
    recipe parent install-doc-manpages install-doc
    recipe parent install-doc install

    recipe parent drop-doc-html     drop-doc
    recipe parent drop-doc-manpages drop-doc
    recipe parent drop-doc drop
    return
}

# # ## ### ##### ######## ############# #####################
return
