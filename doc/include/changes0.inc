[subsection {Changes for version 0}]

This is the first release of kettle, packages and application.
The changes therefore describe the initial features of the system.

[para] In detail:

[list_begin enumerated]
[comment {- - -- --- ----- -------- ------------- ---------------------}]
[enum] 	Kettle requires Tcl 8.5 or higher. Tcl 8.4 or less is not
	supported.

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[enum]	The application [cmd kettle] provides standard setup to run
	a file [file build.tcl], specified either explicitly via option
	[option -f], or implicitly (current working directory).

[para]	This application can be used as the interpreter of a build
	declaration file as well. In that case option [option -f] must
	be part of the [const {#!}]-line.

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[enum]	A core package [package kettle] managing a database of recipes,
	plus standard code invoked automatically after the processing
	of the build declarations to show help or run a recipe specified
	on the command line.

[para]	Standard recipes provide introspection into the list of known
	recipes, and display of general and recipe-specific help.

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[enum]	Various utility and support packages providing the commands for
	the build declarations, and implementation helpers.

[para]	Currently supported are
[list_begin enumerated]
[enum] (Un)installation of pure Tcl packages.
[enum] (Un)installation of Tcl script applications.
[enum] (Re)generation and (un)installation of (tcllib) doctools based manpages.
[enum] (Re)generation and display of (tklib) diagram based figures.
[list_end]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[list_end]
