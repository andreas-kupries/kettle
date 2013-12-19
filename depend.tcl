# -*- tcl -*- Copyright (c) 2012 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Save requirements, i.e. build dependency information.

namespace eval ::kettle { namespace export depends-on }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::depends-on {args} {
    option set @dependencies $args
    return
}

# # ## ### ##### ######## ############# #####################
return
