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

    io trace {}
    io trace {SCAN tcl packages @ [path sourcedir]/}

    # Heuristic search for packages to install, collect names, versions, and files.
    set packages {}
    path foreach-file [path sourcedir] path {
	if {[catch {
	    path tcl-package-file $path pn pv files
	} apkg]} {
	    err { puts "    Skipped: $apkg" }
	    continue
	}
	if {!$apkg} continue
	lappend packages $files $pn $pv
    }

    foreach {files pn pv} $packages {
	TclSetup $files $pn $pv
    }
    return
}

proc ::kettle::TclSetup {files pn pv} {
    set pkgdir [path libdir [string map {:: _} $pn]$pv]

    recipe define install-package-$pn "Install package $pn $pv" {pkgdir files pn pv} {

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

    } $pkgdir $files $pn $pv

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
    return
}

# # ## ### ##### ######## ############# #####################
return
