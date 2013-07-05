#!/bin/sh
# -*- tcl -*- \
exec ./kettle "$0" "${1+$@}"
kettle tcl
kettle tclapp kettle
