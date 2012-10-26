# -*- tcl -*-
# This file has to have code that works in any version of Tcl that
# the user would want to benchmark.

### This code assumes Tcl 8.5 or higher.
package require Tcl 8.5

#
# RCS: @(#) $Id: libbench.tcl,v 1.4 2008/07/02 23:34:06 andreas_kupries Exp $
#
# Copyright (c) 2000-2001 Jeffrey Hobbs.
# Copyright (c) 2007      Andreas Kupries
#

# This code provides the supporting commands for the execution of a
# benchmark files. It is actually an application and is exec'd by the
# management code.

# Options:
# -help				Print usage message.
# -rmatch <regexp-pattern>	Run only tests whose description matches the pattern.
# -match  <glob-pattern>	Run only tests whose description matches the pattern.
# -interp <name>		Name of the interp running the benchmarks.
# -thread <num>                 Invoke threaded benchmarks, number of threads to use.
# -errors <boolean>             Throw errors, or not.

# Note: If both -match and -rmatch are specified then _both_
# apply. I.e. a benchmark will be run if and only if it matches both
# patterns.

# Benchmark results are usually a time in microseconds, but the
# following special values can occur:
#
# - BAD_RES    - Result from benchmark body does not match expectations.
# - ERR        - Benchmark body aborted with an error.
# - Any string - Forced by error code 666 to pass to management.

#
# We claim all procedures starting with bench*
#

# bench --
#
#   Main bench procedure.
#   The bench test is expected to exit cleanly.  If an error occurs,
#   it will be thrown all the way up.  A bench proc may return the
#   special code 666, which says take the string as the bench value.
#   This is usually used for N/A feature situations.
#
# Arguments:
#
#   -pre	script to run before main timed body
#   -body	script to run as main timed body
#   -post	script to run after main timed body
#   -ipre	script to run before timed body, per iteration of the body.
#   -ipost	script to run after timed body, per iteration of the body.
#   -desc	message text
#   -iterations	<#>
#
# Note:
#
#   Using -ipre and/or -ipost will cause us to compute the average
#   time ourselves, i.e. 'time body 1' n times. Required to ensure
#   that prefix/post operation are executed, yet not timed themselves.
#
# Results:
#
#   Returns nothing
#
# Side effects:
#
#   Sets up data in bench global array
#
proc bench {args} {
    global errorInfo errorCode
    variable kb::config
    upvar 0 kb::config BENCH

    # -pre script
    # -body script
    # -desc msg
    # -post script
    # -ipre script
    # -ipost script
    # -iterations <#>

    array set opts {
	-pre	{}
	-body	{}
	-desc	{}
	-post	{}
	-ipre	{}
	-ipost	{}
    }
    set opts(-iter) $BENCH(ITERS)
    while {[llength $args]} {
	set key [lindex $args 0]
	set val [lindex $args 1]

	switch -glob -- $key {
	    -res*	{ set opts(-res)   $val }
	    -pr*	{ set opts(-pre)   $val }
	    -po*	{ set opts(-post)  $val }
	    -ipr*	{ set opts(-ipre)  $val }
	    -ipo*	{ set opts(-ipost) $val }
	    -bo*	{ set opts(-body)  $val }
	    -de*	{ set opts(-desc)  $val }
	    -it*	{
		# Only change the iterations when it is smaller than
		# the requested default
		if {$opts(-iter) > $val} { set opts(-iter) $val }
	    }
	    default {
		error "unknown option $key"
	    }
	}
	set args [lreplace $args 0 1]
    }

    bench_puts "Running <$opts(-desc)>"
    kb::Note StartBench [list $opts(-desc) $opts(-iter)]

    if {($BENCH(MATCH) ne "") && ![string match $BENCH(MATCH) $opts(-desc)]} {
	kb::Note Skipped $opts(-desc)
	return
    }

    if {($BENCH(RMATCH) ne "") && ![regexp $BENCH(RMATCH) $opts(-desc)]} {
	kb::Note Skipped $opts(-desc)
	return
    }

    if {$opts(-pre) ne ""} {
	uplevel \#0 $opts(-pre)
    }

    if {$opts(-body) ne ""} {
	# Always run it once to remove compile phase confusion
	if {$opts(-ipre) ne ""} {
	    uplevel \#0 $opts(-ipre)
	}
	set code [catch {
	    uplevel \#0 $opts(-body)
	} res]
	if {$opts(-ipost) ne ""} {
	    uplevel \#0 $opts(-ipost)
	}

	if {!$code && [info exists opts(-res)] && ($opts(-res) ne $res)} {
	    if {$BENCH(ERRORS)} {
		return -code error "Result was:\n$res\nResult\
			should have been:\n$opts(-res)"
	    } else {
		set res "BAD_RES"
	    }

	    kb::Note Result [list $opts(-desc) $res]

	} else {
	    if {($opts(-ipre) != "") || ($opts(-ipost) != "")} {
		# We do the averaging on our own, to allow untimed
		# pre/post execution per iteration. We catch and
		# handle problems in the pre/post code as if
		# everything was executed as one block (like it would
		# be in the other path). We are using floating point
		# to avoid integer overflow, easily happening when
		# accumulating a high number (iterations) of large
		# integers (microseconds).

		set total 0.0
		#set total +Inf

		for {set i 1} {$i <= $opts(-iter)} {incr i} {
		    kb::Note Progress [list $opts(-desc) $i]

		    set code 0
		    if {$opts(-ipre) != ""} {
			set code [catch {
			    uplevel \#0 $opts(-ipre)
			} res]
			if {$code} break
		    }
		    set code [catch {
			uplevel \#0 [list time $opts(-body) 1]
		    } res]
		    if {$code} break


		    set now [lindex $res 0]
		    #puts !!$now|$total|$opts(-desc)

		    set total [expr {$total + $now}]
		    #if {$now < $total} { set total $now }

		    if {$opts(-ipost) != ""} {
			set code [catch {
			    uplevel \#0 $opts(-ipost)
			} res]
			if {$code} break
		    }
		}
		# XXX Use 'min' instead of avg?
		if {!$code} {
		    #puts !!!A|$total|$opts(-iter)|[expr {int ($total/$opts(-iter))}]

		    set res [list [expr {$total/$opts(-iter)}] microseconds per iteration]
		    #set res $total
		}
	    } else {
		kb::Note Progress [list $opts(-desc) ----]

		set code [catch {
		    uplevel \#0 [list time $opts(-body) $opts(-iter)]
		} res]
		#puts !!!B|$res|
	    }

	    if {$code == 0} {
		# Get just the microseconds value from the time result
		set res [lindex $res 0]
	    } elseif {$code != 666} {
		# A 666 result code means pass it through to the bench
		# suite. Otherwise throw errors all the way out, unless
		# we specified not to throw errors (option -errors 0 to
		# libbench).
		if {$BENCH(ERRORS)} {
		    return -code $code -errorinfo $errorInfo \
			-errorcode $errorCode
		} else {
		    set res "ERR"
		}
	    }

	    kb::Note Result [list $opts(-desc) $res]
	}
    }

    if {($opts(-post) ne "") && [catch {
	uplevel \#0 $opts(-post)
    } err] && $BENCH(ERRORS)} {
	return -code error "post code threw error:\n$err"
    }
    return
}
