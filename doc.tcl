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

proc ::kettle::doc {{root {}}} {
    # Auto-search for documentation files.

    if {$root eq {}} {
	set root [kettle sources]/doc
    }

    set ok 0
    kettle util foreach-file $root path {
	if {![kettle util docfile $path]} continue
	set ok 1
    }

    if {!$ok} return
    doc::Setup $root
    return
}

proc ::kettle::doc::Setup {root} {

    set topdir [file normalize [kettle sources]]

    kettle::Def doc {
	--
	(Re)generate the documentation embedded in the repository.
    } [list apply {{docroot topdir} {
	set here [pwd]

	cd $docroot
	set dst $topdir/embedded

	puts "Removing old documentation..."
	file delete -force $dst

	file mkdir $dst/man
	file mkdir $dst/www

	## TODO ## Put the exec calls into a utility command which
	## ensures proper output to the gui as well.

	puts "Generating man pages..."
	exec 2>@ stderr >@ stdout dtplite -ext n -o $dst/man nroff .

	puts "Generating 1st html..."
	exec 2>@ stderr >@ stdout dtplite -merge -o $dst/www html .
	puts "Generating 2nd html, resolving cross-references..."
	exec 2>@ stderr >@ stdout dtplite -merge -o $dst/www html .

	cd  $dst/man
	file delete -force .idxdoc .tocdoc
	cd  ../www
	file delete -force .idxdoc .tocdoc

	cd $here
    }} $root $topdir]

    foreach r {install install-doc install-manpages} {
	kettle::Def $r {
	    ?lib-directory?
	    Install manpages in the man/ directory.
	} [list apply {{src} {
	    # ... embedded/man
	    set dst [kettle util mandir]/mann
	    foreach m [glob -directory $src *] {
		file copy -force $m $dst
	    }
	    return
	}} $topdir/embedded/man/files]
    }

    foreach r {install install-doc install-htmldoc} {
	kettle::Def $r {
	    ?lib-directory?
	    Install HTML documentation in the html/ directory.
	} [list apply {{src name} {
	    # ... embedded/ww

	    set dst [kettle util htmldir]/$name

	    file mkdir ${dst}-new
	    file copy -force {*} [glob -directory $src *] ${dst}-new

	    catch { file rename -force $dst ${dst}-old }
	    file rename -force ${dst}-new $dst
	    file delete -force ${dst}-old
	    return
	}} $topdir/embedded/www [file tail $topdir]]
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Ready

package provide kettle::doc 0
return

# # ## ### ##### ######## ############# #####################
