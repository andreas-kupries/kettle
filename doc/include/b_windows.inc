[subsection {Build & Installation (Windows)}]

This section describes the actions required to install Kettle on Windows(tm)
systems.

If you have to install Kettle on a Unix machine (Linux, BSD, and
related, including OS X) see section
[sectref {Build & Installation (Unix)}] instead.

[para] To install Kettle simply run

[example {
    /path/to/tclsh8.5 /path/to/kettle/kettle -f /path/to/kettle/build.tcl install
}]

where [file /path/to/tclsh8.5] is the tclsh of your Tcl installation,
and [file /path/to/kettle] the location of the Kettle sources on your
system.

Please note that and how we are using the non-installed
[syscmd kettle] application found in the sources to install itself.

[comment { -- Check dependency on working directory!
	-- -- Can we do this inside and outside the kettle sources ?
}]

[para]

This will build the package and application and then places them into
directories where the [cmd tclsh8.5] will find them. Note that the
installed kettle application is modified to use the chosen tclsh
instead of searching for one on the [var PATH].

[para] The above is written without assuming any associations from
extensions (like [file .tcl]) to executables responsible for the file
with that extension.

Actually, given that [file build.tcl] is technically a
[file kettle]-script, which in turn is a [file .tcl]-script I am not
sure if Windows is able to handle such a chain of interpreters.

The command given above simply spells out the entire chain.

[para]

The build system provides a small GUI for those not comfortable with
the command line.

This GUI is accessible by invoking [file build.tcl] without any
arguments from the command line.

[para]

To get help about the methods of [file build.tcl], and their complete
syntax, invoke [file build.tcl] with argument [method help], i.e.,
like

[example {
    /path/to/tclsh8.5 /path/to/kettle/kettle -f /path/to/kettle/build.tcl help
}]
