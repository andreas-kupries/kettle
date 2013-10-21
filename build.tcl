#!/bin/sh
# -*- tcl -*- \
exec ./kettle "$0" "${1+$@}"
# For kettle sources, documentation, etc. see
# - http://core.tcl.tk/akupries/kettle
# - http://chiselapp.com/user/andreas_kupries/repository/Kettle
kettle tcl
kettle tclapp kettle
