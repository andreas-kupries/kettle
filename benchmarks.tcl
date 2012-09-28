# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Handle a tcltest-based benchmarks

namespace eval ::kettle { namespace export benchmarks }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::benchmarks {{benchsrcdir bench}} {
    # Overwrite self, we run only once for effect.
    proc ::kettle::benchmarks args {}

    # Heuristic search for benchmarks
    # Aborts caller when nothing is found.
   lassign [path scan \
		{tclbench benchmarks} \
		$benchsrcdir \
		{path bench-file}] \
	root benchmarks

    # Put the benchmarks into recipes.

    recipe define test {
	Run the benchmarks
    } {benchsrcdir benchmarks} {

	# TODO ####

    } $root $benchmarks

    return
}

# # ## ### ##### ######## ############# #####################
return
