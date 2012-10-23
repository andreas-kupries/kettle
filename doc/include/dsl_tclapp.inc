[comment {--- !doctools ---}]
[comment { DSL :: kettle tclapp :: }]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[call [cmd {kettle tclapp}] [arg path]]

This command declares the presence of a Tcl script application found 
at the [arg path] under the package source directory.

[para] If the specified application is found the command will define
two recipes to install and uninstall this application, namely:

[list_begin definitions]
[def [const install-app-[arg path]]]
[def [const uninstall-app-[arg path]]]
[list_end]

[para] It will further extend the recipes
[list_begin definitions]
[def [const install-tcl-applications]]
[def [const install-applications]]
[def [const install]]
[def [const uninstall-tcl-applications]]
[def [const uninstall-applications]]
[def [const uninstall]]
[list_end]

This enables the package builder to (un)install the application as
part of various groups.

[para] Applications are installed into the application bin/ directory
(--bin-dir, despite technically not being binary files).

[list_begin options]
[include o_bindir.inc]
[list_end]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
