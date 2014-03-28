[subsection {Build & Installation (Unix)}]

This section describes the actions required to install Kettle on Unix
systems (Linux, BSD, and related, including OS X).

If you have to install Kettle on a Windows machine see section
[sectref {Build & Installation (Windows)}] instead.

[para] To install Kettle simply run

[example {
    /path/to/tclsh8.5 /path/to/kettle/build.tcl install
}]

where [file /path/to/tclsh8.5] is the tclsh of your Tcl installation, and
[file /path/to/kettle] the location of the Kettle sources on your system.

[comment { -- Check dependency on working directory!
	-- -- Can we do this inside and outside the kettle sources ?
}]

[para]

This will build the package and application and then places them into
directories where the [cmd tclsh8.5] will find them. Note that the
installed kettle application is modified to use the chosen tclsh
instead of searching for one on the [var PATH].

[para]

The build system provides a small GUI for those not comfortable with
the command line.

This GUI is accessible by invoking [file build.tcl] without any
arguments.

[para]

To get help about the methods of [file build.tcl], and their complete
syntax, invoke [file build.tcl] with argument [method help], i.e.,
like

[example {
    /path/to/tclsh8.5 /path/to/kettle/build.tcl help
}]
