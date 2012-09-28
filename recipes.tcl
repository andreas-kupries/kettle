# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Recipe management commands. Core definition and execution.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definition code, higher control).

namespace eval ::kettle::recipe {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## System state

namespace eval ::kettle::recipe {
    # Dictionary of recipe definitions.
    # name -> dict (
    #      script -> list ( tcl scripts )
    #      help   -> list ( help strings )
    #      parent -> parent recipe, if any. empty if there is none.
    # )

    variable recipe {}

    # Import the supporting utilities used here.
    namespace import ::kettle::io
    namespace import ::kettle::status
}

# # ## ### ##### ######## ############# #####################
## Management API commands.

proc ::kettle::recipe::define {name description arguments script args} {
    variable recipe

    # Note! The scripts are evaluated in the context of namespace
    # ::kettle. This provide access to various internal commands
    # without making them visible to the user/DSL.

    set description [Reflow $description]
    io trace {DEF $name}

    Init $name
    dict update recipe $name def {
	dict lappend def script \
	    [lambda@ ::kettle $arguments $script {*}$args]
	dict lappend def help   $description
    }
    return
}

proc ::kettle::recipe::parent {name parent} {
    variable recipe

    Init $name
    Init $parent
    dict update recipe $name def {
	dict lappend def parent $parent
    }

    #io trace {PARENTS $name = [dict get $recipe $name parent]}
    return
}

proc ::kettle::recipe::exists {name} {
    variable recipe
    return [dict exists $recipe $name]
}

proc ::kettle::recipe::names {} {
    variable recipe
    return [dict keys $recipe]
}

proc ::kettle::recipe::help {prefix} {
    global   argv0
    variable recipe
    append prefix $argv0 " "

    foreach goal [lsort -dict [dict keys $recipe]] {
	io puts ""
	io note { io puts $prefix${goal} }

	set children [Children $goal]
	set help     [dict get $recipe $goal help]

	if {[llength $children]} {
	    io puts "\t==> [join [lsort -dict $children] "\n\t==> "]"
	}
	if {[llength $help]} {
	    io puts [join $help \n]
	}
    }

    return
}

proc ::kettle::recipe::run {args} {
    io trace {}

    set done {}
    status ok

    if {[catch {
	foreach goal $args {
	    Run $goal
	    status show
	}
    }]} {
	io err { io puts $::errorInfo }
    }
}

# # ## ### ##### ######## ############# #####################
## Internal support.

proc ::kettle::recipe::Init {name} {
    variable recipe
    if {[dict exists $recipe $name]} return
    dict set recipe $name {
	script {}
	help   {}
	parent {}
    }
    return
}

proc ::kettle::recipe::Run {name} {
    variable recipe
    upvar 1 done done

    if {![dict exists $recipe $name]} {
	return -code error "No definition for \"$name\""
    }

    # Ignore goals already executed.
    if {[dict exists $done $name]} return
    dict set done $name .

    # Determine the recipe's children and run them first.
    foreach c [Children $name] {
	Run $c
    }

    # Now run the recipe itself
    io trace {RUN ($name) ...}
    foreach cmd [dict get $recipe $name script] {
	#io puts |$cmd|
	eval $cmd
    }
    return
}

proc ::kettle::recipe::Children {name} {
    # Determine the recipe's children
    variable recipe
    set result {}
    dict for {c v} $recipe {
	if {$name ni [dict get $v parent]} continue
	lappend result $c
    }
    return $result
}

proc ::kettle::recipe::Reflow {help} {
    return [Indent [Undent [string trim $help]] {    }]
}

proc ::kettle::recipe::Indent {text prefix} {
    set text [string trimright $text]
    set res {}
    foreach line [split $text \n] {
	if {[string trim $line] eq {}} {
	    lappend res {}
	} else {
	    lappend res $prefix[string trimright $line]
	}
    }
    return [join $res \n]
}

proc ::kettle::recipe::Undent {text} {
    if {$text eq {}} { return {} }

    set lines [split $text \n]
    set ne {}
    foreach l $lines {
	if {[string length [string trim $l]] == 0} continue
	lappend ne $l
    }

    set lcp [LCP $ne]
    if {$lcp eq {}} { return $text }

    regexp "^(\[\t \]*)" $lcp -> lcp
    if {$lcp eq {}} { return $text }

    set len [string length $lcp]

    set res {}
    foreach l $lines {
	if {[string trim $l] eq {}} {
	    lappend res {}
	} else {
	    lappend res [string range $l $len end]
	}
    }
    return [join $res \n]
}

proc ::kettle::recipe::LCP {list} {
    if {[llength $list] <= 1} {
	return [lindex $list 0]
    }

    set list [lsort $list]
    set min [lindex $list 0]
    set max [lindex $list end]

    # Min and max are the two strings which are most different. If
    # they have a common prefix, it will also be the common prefix for
    # all of them.

    # Fast bailouts for common cases.

    set n [string length $min]
    if {$n == 0}      { return "" }
    if {$min eq $max} { return $min }

    set prefix ""
    set i 0
    while {[string index $min $i] eq [string index $max $i]} {
	append prefix [string index $min $i]
	if {[incr i] > $n} {break}
    }
    return $prefix
}

# # ## ### ##### ######## ############# #####################
return
