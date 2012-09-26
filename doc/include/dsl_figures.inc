[comment {--- !doctools ---}]
[comment { DSL :: kettle figures :: }]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[call [cmd {kettle figures}] [opt [arg figroot]]]

This command declares the presence of [package diagram]-based figures
under the directory [arg figroot], which is a path relative to the
source directory we are in.

[para] If not specified [arg figroot] defaults to [file doc/figures].

[para] If figures are found the command will define two recipes,
"figures" and "show-figures". When invoked the first will convert the
figures into raster images in PNG format and save them as siblings to
their source files. The second will launch a [package Tk]-based GUI
rendering the figures to a canvas.

[para] Now for various important notes, limitations, etc.:

[list_begin enumerated]

[enum]	This command is run for effect only once, even if invoked
	multiple times. First invocation wins.

[enum]	This command is run implicitly by [cmd {kettle doc}], using
	its [arg docroot] as basis for [arg figroot], i.e.
	[file [arg docroot]/figures].

[enum]	The previous two items together mean that any non-standard
	settings for the figure root must come before
	[cmd {kettle doc}], if that command is used, directly, or
	indirectly (like through [cmd {kettle tcl}], for example).

[enum]	Diagram files are recognized by containing the marker

	[list_begin itemized]
	[item] "[const "tcl\.tk//DSL diagram//EN//"]"
	[list_end]

	in their first 1024 characters.

[enum]	The two recipes use the tklib [syscmd dia] application to
	perform the conversion and GUI display. They will fail if
	this application cannot be found on the [var PATH].

[list_end]

[comment {- - -- --- ----- -------- ------------- ---------------------}]
