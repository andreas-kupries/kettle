[comment {--- !doctools ---}]
[comment { option :: --prefix :: }]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[opt_def --prefix path]

This configuration option specifies the path to the root directory for
all platform-independent (non-binary) installation files.

[para] The default value is the twice parent of the
[lb][cmd {info library}][rb] directory of the [syscmd tclsh] used to
run the [syscmd kettle] application. In code:

[para][example {set prefix [file dirname [file dirname [info library]]]}]

[para] An exception is made if the [cmd {info library}] result refers to
a zip archive instead of disk. In that case the default value is the
[file lib] directory which is sibling to the [file bin] directory containing
the [syscmd tclsh] used to run the [syscmd kettle] application. In code:

[para][example {set prefix [file join [file dirname [file dirname [info nameofexecutable]]] lib]}]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
