[comment {--- !doctools ---}]
[comment { option :: --lib-dir :: }]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[opt_def --lib-dir path]

This configuration option specifies the path to the directory packages
(binary and script) will be installed into.

[para] The default value is the [lb][cmd {info library}][rb] directory
of the [syscmd tclsh] used to run the [syscmd kettle] application. In code:

[para][example {set libdir [info library]}]

[para] An exception is made if the [cmd {info library}] result refers to
a zip archive instead of disk. In that case the default value is the
[file lib] directory which is sibling to the [file bin] directory containing
the [syscmd tclsh] used to run the [syscmd kettle] application. In code:

[para][example {set libdir [file join [file dirname [file dirname [info nameofexecutable]]] lib]}]

[para] If the option [option --exec-prefix] is modified the default
value changes to [file [var --exec-prefix]/lib].

[comment {- - -- --- ----- -------- ------------- ---------------------}]
