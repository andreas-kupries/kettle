#!kettle -f
# Special code: Direct load of the relevant packages.
# For ourselves we can't assume that we are installed, and even if so,
# it may an older, unusable version.
source [kettle path tclapp.tcl] ; kettle tclapp kettle
#kettle tcl
