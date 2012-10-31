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
