# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle tcllib/doctools documentation files

namespace eval ::kettle { namespace export doc doc-destination }

kettle option define --doc-destination {} {}
kettle option setd   --doc-destination embedded

kettle tool declare {
    dtplite dtplite.kit dtplite.tcl dtplite.exe
}

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

    # Heuristic search for documentation files.
    # Aborts caller when nothing is found.
    lassign [path scan \
		 tcllib/doctools \
		 $docsrcdir \
		 {path doctools-file}] \
	root manpages

    # Put the documentation into recipes.

    set dd      [path sourcedir [option get --doc-destination]]
    set mansrc  $dd/man/files
    set htmlsrc $dd/www

    set mandst  [path mandir  mann]
    set htmldst [path htmldir [file tail [path sourcedir]]]

    recipe define doc {
	(Re)generate the documentation embedded in the repository.
    } {root dst} {
	path in $root {
	    # Validate tool presence before actually doing anything
	    tool get dtplite

	    io puts "Removing old documentation..."
	    file delete -force $dst

	    file mkdir $dst/man
	    file mkdir $dst/www

	    io puts "Generating man pages..."
	    path exec {*}[tool get dtplite] -ext n -o $dst/man nroff .

	    # Note: Might be better to run them separately.
	    # Note @: Or we shuffle the results a bit more in the post processing stage.

	    io puts "Generating HTML... Pass 1, draft..."
	    path exec {*}[tool get dtplite] -merge -o $dst/www html .

	    io puts "Generating HTML... Pass 2, resolving cross-references..."
	    path exec {*}[tool get dtplite] -merge -o $dst/www html .

	    # Remove some of the generated files, consider them transient.
	    cd  $dst/man ; file delete -force .idxdoc .tocdoc
	    cd  ../www   ; file delete -force .idxdoc .tocdoc
	}
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
