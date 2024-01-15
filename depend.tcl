# -*- tcl -*- Copyright (c) 2012-2024 Andreas Kupries
# # ## ### ##### ######## ############# #####################
## Save requirements, i.e. build dependency information.

namespace eval ::kettle { namespace export require }

# # ## ### ##### ######## ############# #####################
## API.

proc ::kettle::depends-on {args} {
    option set @dependencies $args
    return
}

# # ## ### ##### ######## ############# #####################
return
