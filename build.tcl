#!/bin/sh
# -*- tcl -*- \
exec ./kettle -f "$0" "${1+$@}"
# Special code: Direct load of the relevant packages.
# For ourselves we can't assume that we are installed, and even if so,
# it may an older, unusable version.
catch {
    source [kettle path util.tcl]
    source [kettle path tclapp.tcl]
    source [kettle path tcl.tcl]
    source [kettle path doc.tcl]
}
kettle doc
kettle tcl
kettle tclapp kettle
