

To install XXX simply run

[example {
    /path/to/tclsh8.5 /path/to/xxx/build.tcl install
}]

where [file /path/to/tclsh8.5] is the tclsh of your Tcl installation, and
[file /path/to/xxx] the location of the XXX sources on your system.

[para]

This builds all packages and then places them in a directory where the
[cmd tclsh8.5] will find them. 

[para]

On Windows you can invoke the file [file build.tcl] with a
double-click.  This will pop up a small graphical interface for
entering the destination and performing the installation. This
handling of a double-click is restricted to Windows only however.

[para]

On unix the same GUI is acessible by invoking [file build.tcl] without
any arguments.

[para]

To get help about the methods of [file build.tcl], and their complete
syntax, invoke  [file build.tcl] with argument [method help], i.e., like

[example {
    /path/to/tclsh8.5 /path/to/xxx/build.tcl help
}]
