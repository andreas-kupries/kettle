## doc.tcl --
# # ## ### ##### ######## ############# #####################
#
#	'kettle doc' command
#
# Copyright (c) 2012 Andreas Kupries

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require kettle ; # core
package require kettle::util

# # ## ### ##### ######## ############# #####################
## State, Initialization

namespace eval ::kettle::doc {}

# # ## ### ##### ######## ############# #####################
## API.

option: --doc-destination embedded

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

    option: --doc-destination $dstdir
    return
}

proc ::kettle::doc {{docsrcdir doc}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::doc args {}

    set ndocsrcdir [norm $docsrcdir]
    set n [llength [file split $ndocsrcdir]]

    # Heuristic search for figures
    kettle figures $docsrcdir/figures

    log {}
    log {SCAN tcllib/doctools @ $docsrcdir/}

    # Heuristic search for documentation files.
    set manpages {}
    util foreach-file $ndocsrcdir path {
	if {![util docfile $path]} continue

	set path [file join {*}[lrange [file split $path] $n end]] 

	log {    Accepted: $docsrcdir/$path}
	lappend manpages $path
    }

    if {![llength $manpages]} return
    doc::Setup $ndocsrcdir $manpages
    return
}

proc ::kettle::doc::Dest {} {
    return [kettle option-get --doc-destination]
}

proc ::kettle::doc::Setup {docsrcdir manpages} {

    kettle::Def doc {
	(Re)generate the documentation embedded in the repository.
    } [list apply {{docsrcdir} {

	set here [pwd]
	set dst  [sources [doc::Dest]]

	cd $docsrcdir

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
    } ::kettle} $docsrcdir]

    kettle::Def install-doc-manpages {
	Install manpages
    } {
	set src [sources [doc::Dest]/man/files]
	set dst [mandir]/mann

	util install-file-set "manpages" \
	    $dst {*}[glob -directory $src *.n]
	return
    }

    kettle::Def install-doc-html {
	Install HTML documentation
    } {
	set src [sources [doc::Dest]/www]
	set dst [htmldir]/[file tail [sources]]

	util install-file-group "HTML documentation" \
	    $dst {*}[glob -directory $src *]
	return
    }

    kettle::Def drop-doc-manpages {
	Uninstall manpages
    } {
	set src [sources [doc::Dest]/man/files]
	set dst [mandir]/mann

	util uninstall-file-set "manpages" \
	    $dst {*}[glob -directory $src -tails *.n]
	return
    }

    kettle::Def drop-doc-html {
	Uninstall HTML documentation
    } {
	set dst [htmldir]/[file tail [sources]]
	util uninstall-file-group "HTML documentation" $dst
	return
    }

    kettle::SetParent install-doc-html     install-doc
    kettle::SetParent install-doc-manpages install-doc
    kettle::SetParent install-doc install

    kettle::SetParent drop-doc-html     drop-doc
    kettle::SetParent drop-doc-manpages drop-doc
    kettle::SetParent drop-doc drop
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::doc 0
return

# # ## ### ##### ######## ############# #####################
