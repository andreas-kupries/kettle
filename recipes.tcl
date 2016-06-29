# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Recipe management commands. Core definition and execution.

# # ## ### ##### ######## ############# #####################
## Export (internals - recipe definition code, higher control).

namespace eval ::kettle::recipe {
    namespace export {[a-z]*}
    namespace ensemble create

    namespace import ::kettle::strutil
    namespace import ::kettle::path
    namespace import ::kettle::option
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

proc ::kettle::recipe::anchor {path description {mode all}} {
    if {$mode eq "all"} {
	set spec  [subst -nocommands -nobackslashes {
	    description {}
	    private all {
		section Targets Project
		description {$description}
	    } ::kettle::recipe::RunSiblings
	    default all
	}]
    } else {
	set spec [subst -nocommands -nobackslashes {
	    description {$description}
	}]
    }
    kettle cli phantom $path $spec
    return
}

proc ::kettle::recipe::RunSiblings {config} {
    # Determine the sibling commands, and run them.

    set super [$config context super]
    set self  [$super default]

    foreach sibling [lsort -dict [$super known]] {
	# Ignore ourselves and the auto-generated commands.
	if {$sibling eq $self} continue
	if {$sibling in {exit help}} continue

	# Alternate: Exclude privates which do not have the recipe
	# action callback.

	# Run the sibling.
	# TODO: see if we can propagate the config into the sub-ordinates.
	# - Might require our own dispatch to directly access the action callback.
	# - Or a variant of do taking the config to use.
	# - This becomes critical when construction reaches option handling.

	[$super lookup $sibling] do
    }
    return
}

proc ::kettle::recipe::defx {name description cmdprefix} {
    # Note! The scripts are evaluated in the context of namespace
    # ::kettle. This provide access to various internal commands
    # without making them visible to the user/DSL.

    set description [strutil reflow $description]
    io trace {DEF $name}

    kettle cli extend $name [subst -nocommands -nobackslashes {
	section Targets Project
	# parameters -> only options, define dynamically
	description {$description}
    }] [list ::kettle::recipe::RunCmd $name $cmdprefix]
    return
}

proc ::kettle::recipe::RunCmd {name cmdprefix config} {
    # config => options
    # dynamically save the information somewhere.
    # maybe just save 'config'

    try {
	status begin $name

	# Now run the recipe itself
	io trace {RUN ($name) ... BEGIN}

	if {![option get --machine]} {
	    io note { io puts -nonewline "\n${name}: " }
	}

	try {
	    {*}$cmdprefix
	    status ok
	} trap {KETTLE STATUS OK}   {e o} {
	    io trace {RUN ($name) ... OK}
	    # nothing - implied continue
	} trap {KETTLE STATUS FAIL} {e o} {
	    io trace {RUN ($name) ... FAIL}
	    # nothing - implied break
	}
    }
    return
}

# # ## ### ##### ######## ############# ##########

proc ::kettle::recipe::define {name description arguments script args} {
    variable recipe

    # Note! The scripts are evaluated in the context of namespace
    # ::kettle. This provide access to various internal commands
    # without making them visible to the user/DSL.

    set description [strutil reflow $description]
    io trace {DEF $name}

    Init $name $description

    dict update recipe $name def {
	dict lappend def script \
	    [lambda@ ::kettle $arguments $script {*}$args]
    }
    return
}

proc ::kettle::recipe::parent {name parent} {
return
    variable recipe

    Init $name
    Init $parent
    dict update recipe $name def {
	dict lappend def parent $parent
    }

    set cmd [dict get $recipe $parent handler]

    set d [split [$cmd description] \n]
    lappend d "\t==> $name"
    $cmd description: [join [lsort -dict [lsort -unique $d]] \n]

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

# Remove
proc ::kettle::recipe::help {prefix} {

    error not-yet-implemented--redirect-into-cli hierarchy
    kettle cli help

    global   argv0
    variable recipe
    append prefix $argv0 " -f " [path relativecwd [path script]] " "

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
    io puts ""
    return
}

# TODO: Remove/replace
proc ::kettle::recipe::help-dump {} {
    variable recipe
    foreach goal [lsort -dict [dict keys $recipe]] {
	set children [Children $goal]
	set help     [dict get $recipe $goal help]

	set lines {}
	if {[llength $children]} {
	    lappend lines "\t==> [join [lsort -dict $children] "\n\t==> "]"
	}
	if {[llength $help]} {
	    lappend lines [join $help \n]
	}

	lappend result $goal [join $lines \n]
    }

    io puts $result
    return
}

proc ::kettle::recipe::run {args} {
    io trace {}
    foreach goal $args {
	try {
	    Run $goal
	}
    }
    return
}

# # ## ### ##### ######## ############# #####################
## Internal support.

proc ::kettle::recipe::Init {name {description {}}} {
    variable recipe

    if {[dict exists $recipe $name]} return
    dict set recipe $name {
	script {}
	help   {}
	parent {}
    }

    set cmd [kettle cli extend $name [subst -nocommands -nobackslashes {
	section Targets Project
	# parameters -> only options, define dynamically
	description {$description}
    }] [list ::kettle::recipe::RunIt $name]]

    # Remember reference to handler for future modifications.
    dict set recipe $name handler $cmd
    return
}

proc ::kettle::recipe::RunIt {name config} {
    # config => options
    try {
	Run $name
    }
}

proc ::kettle::recipe::Run {name} {
    variable recipe
    upvar 1 done done

    status begin $name

    if {![dict exists $recipe $name]} {
	status fail "No definition for recipe \"$name\""
    }

    # Determine the recipe's children and run them first.
    foreach c [Children $name] {
	Run $c
	if {[status is $c] ne "ok"} {
	    io trace {RUN ($name) ... FAIL (inherited)}
	    catch { status fail "Sub-goal \"$c\" failed" }
	    return
	}
    }

    # Now run the recipe itself
    io trace {RUN ($name) ... BEGIN}

    set commands [dict get $recipe $name script]
    if {![llength $commands]} {
	io trace {RUN ($name) ... OK (nothing)}
	catch { status ok }
	return
    }

    foreach cmd $commands {
	if {![option get --machine]} {
	    io note { io puts -nonewline "\n${name}: " }
	}
	try {
	    eval $cmd
	    status ok
	} trap {KETTLE STATUS OK}   {e o} {
	    io trace {RUN ($name) ... OK}
	    # nothing - implied continue
	} trap {KETTLE STATUS FAIL} {e o} {
	    io trace {RUN ($name) ... FAIL}
	    break
	}
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

# # ## ### ##### ######## ############# #####################
return
