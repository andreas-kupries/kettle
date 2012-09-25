## doc.tcl --
# # ## ### ##### ######## ############# #####################
#
#	'kettle doc' command
#
# Copyright (c) 2012 Andreas Kupries

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require  kettle ; # core
package require  kettle::util

# # ## ### ##### ######## ############# #####################
## State, Initialization

namespace eval ::kettle::doc {}

# # ## ### ##### ######## ############# #####################
## API.

option: --doc-destination embedded

proc ::kettle::doc-destination {dstdir} {
    # TODO: Reject absolute path.
    # TODO: Reject path outside of sources?
    option: --doc-destination $dstdir
    return
}

proc ::kettle::doc {{docsrcdir {}}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::doc args {}

    # Auto-search for documentation files.

    if {$docsrcdir eq {}} {
	set docsrcdir [kettle sources doc]
    } else {
	set docsrcdir [kettle norm $docsrcdir]
    }

    set ok 0
    kettle util foreach-file $docsrcdir path {
	if {![kettle util docfile $path]} continue
	set ok 1
	break
    }

    if {!$ok} return
    doc::Setup $docsrcdir
    return
}

proc ::kettle::doc::Dest {} {
    return [kettle option-get --doc-destination]
}

proc ::kettle::doc::Setup {docsrcdir} {

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
	set dst [htmldir]/[file dirname [sources]]

	util install-file-group "HTML documentation" \
	    $dst {*}[glob -directory $src *]
	return
    }

    kettle::SetParent install-doc-html     install-doc
    kettle::SetParent install-doc-manpages install-doc
    kettle::SetParent install-doc install

    ## TODO ## uninstallation of documentation ...
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::doc 0
return

# # ## ### ##### ######## ############# #####################
