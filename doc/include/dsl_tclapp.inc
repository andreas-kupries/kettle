[comment {--- !doctools ---}]
[comment { DSL :: kettle tclapp :: }]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[call [cmd {kettle tclapp}] [arg path]]

This command declares the presence of a Tcl script application found 
at the [arg path] under the package source directory.

[para] If the specified application is found the command will define
two recipes to install and uninstall this application, with the names
"install-app-[arg path]" and ""drop-app-[arg path]".

[para] It will further extend the recipes "install-tcl-applications",
"install-applications", "install", "drop-tcl-applications",
"drop-applications", and "drop".  This enables the package builder to
(un)install the application as part of various groups.

[comment { ## TODO ## Describe --bin-dir, and defaults }]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
