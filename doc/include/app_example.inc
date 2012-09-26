[comment {--- !doctools ---}]
[comment { DSL :: kettle application :: example :: }]

A simple example of a build.tcl script is that for kettle itself.

[para] Stripping out the special code taking core of the fact that it
cannot assume to be installed already this reduces to the code below,
and of that only the last two lines are relevant in terms of build
declarations. The first three are the magic to find and run the kettle
application in the [var PATH]
(The actual code assumes that [cmd kettle] is found the working
directory, again it cannot assume to be installed already).

[para][example_begin]
#!/bin/sh
# -*- tcl -*- \
exec kettle -f "$0" "${1+$@}"
kettle tcl
kettle tclapp kettle
[example_end]

[para] We ask it to search for and handle all Tcl script packages to
be found in the directory of the [file build.tcl] file, and that we
have one script application in that same directory.

As the documentation files and figures are in the standard locations,
we let [cmd {kettle tcl}] handle them implicitly.

[para] Done.
