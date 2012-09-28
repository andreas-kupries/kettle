# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle tklib/diagram figures (documentation)

namespace eval ::kettle { namespace export tcl }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::tcl {} {

    # Heuristic search for documentation, testsuites, benchmarks.
    doc
    testsuite
    benchmarks

    # Heuristic search for packages to install, collect names, versions, and files.
    # Aborts caller when nothing is found.
    lassign [path scan \
		 {tcl packages}\
		 [path sourcedir] \
		 {path tcl-package-file}] \
	root packages

    foreach {files pn pv} $packages {
	TclSetup $root $files $pn $pv
    }
    return
}

proc ::kettle::TclSetup {root files pn pv} {
    set pkgdir [path libdir [string map {:: _} $pn]$pv]

    recipe define install-package-$pn "Install package $pn $pv" {pkgdir root files pn pv} {
	path in $root {
	    set tmpdir [path tmpfile]
	    file mkdir  $tmpdir
	    set tmpfile $tmpdir/pkgIndex.tcl

	    set primary [lindex $files 0]
	    path write $tmpfile \
		"package ifneeded [list $pn] $pv \[list source \[file join \$dir [file tail $primary]]]"

	    path install-file-group \
		"package $pn $pv" \
		$pkgdir {*}$files $tmpfile

	    file delete $tmpfile
	    file delete $tmpdir
	}
    } $pkgdir $root $files $pn $pv

   recipe define drop-package-$pn "Uninstall package $pn $pv" {pkgdir pn pv} {
       path uninstall-file-group "package $pn $pv" $pkgdir
   } $pkgdir $pn $pv

    # Hook the package specific recipes into a hierarchy of more
    # general recipes.

    recipe parent install-package-$pn  install-tcl-packages
    recipe parent install-tcl-packages install-packages
    recipe parent install-packages     install

    recipe parent drop-package-$pn  drop-tcl-packages
    recipe parent drop-tcl-packages drop-packages
    recipe parent drop-packages     drop

    recipe parent install-package-$pn debug-package-$pn  
    recipe parent debug-package-$pn   debug-tcl-packages
    recipe parent debug-tcl-packages  debug-packages
    recipe parent debug-packages      debug
    return
}

# # ## ### ##### ######## ############# #####################
return
