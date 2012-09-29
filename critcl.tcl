
install
dst/target-config

	if {$config ne {}} {
	    RunCritcl -target $config -cache [pwd]/BUILD.$p -libdir $ldir -includedir $idir -pkg $src
	} else {
	    RunCritcl -cache [pwd]/BUILD.$p -libdir $ldir -includedir $idir -pkg $src
	}

	if {![file exists $ldir/$p]} {
	    set ::NOTE {warn {DONE, with FAILURES}}
	    break
	}



debug

	if {$config ne {}} {
	    RunCritcl -keep -debug all -target $config -cache [pwd]/BUILD.$p -libdir $ldir -includedir $idir -pkg $src
	} else {
	    RunCritcl -keep -debug all -cache [pwd]/BUILD.$p -libdir $ldir -includedir $idir -pkg $src
	}

	if {![file exists $ldir/$p]} {
	    set ::NOTE {warn {DONE, with FAILURES}}
	    break
	}



proc RunCritcl {args} {
    #puts [info level 0]
    if {![catch {
	package require critcl::app 3.1
    }]} {
	#puts "......... [package ifneeded critcl::app [package present critcl::app]]"
	critcl::app::main $args
	return
    } else {
	foreach cmd {
	    critcl3 critcl3.kit critcl3.tcl critcl3.exe
	    critcl critcl.kit critcl.tcl critcl.exe
	} {
	    # Locate the candidate.
	    set cmd [auto_execok $cmd]

	    # Ignore applications which were not found.
	    if {![llength $cmd]} continue

	    # Proper native path needed, especially on windows. On
	    # windows this also works (best) with a starpack for
	    # critcl, instead of a starkit.

	    set cmd [file nativename [lindex [auto_execok $cmd] 0]]

	    # Ignore applications which are too old to support
	    # -v|--version, or are too old as per their returned
	    # version.
	    if {[catch {
		set v [eval [list exec $cmd --version]]
	    }] || ([package vcompare $v 3.1] < 0)} continue

	    # Perform the requested action.
	    set cmd [list exec 2>@ stderr >@ stdout $cmd {*}$args]
	    #puts "......... $cmd"
	    eval $cmd
	    return
	}
    }

    puts "Unable to find a usable critcl 3.1 application (package). Stop."
    ::exit 1
}
