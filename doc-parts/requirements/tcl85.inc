
[subsection Tcl]

A working Tcl installation is needed, however as we are building a Tcl
package that should be pretty much obvious, and I will not belabor the
point.

[para] Use whatever you are comfortable with, as long as it provides
Tcl 8.5, or higher, Tk 8.5 or higher, and the img::png package, a part
of TkImg.

[para] An easy way to get an installation of a recent Tcl 8.5 and the
mentioned packages, which I recommend, is to download and install
[uri http://www.activestate.com ActiveState's]
[uri http://www.activestate.com/activetcl ActiveTcl] for your platform.
Follow the link for ActiveTcl to find it.

[para] After the installation of ActiveTcl 8.5 in a directory of your
choice run the command

[example {
    teacup update
}]

This will install a lot more packages than found in the distribution
alone.

(Disclosure: I, Andreas Kupries, work for ActiveState, maintaining
ActiveTcl and TclDevKit).

[para] For those wishing to build either Tcl/Tk and/or TkImg on their
own, these can found at

[list_begin definitions]
[def Tcl]   [uri http://core.tcl.tk/tcl/]
[def Tk]    [uri http://core.tcl.tk/tk/]
[def TkImg] [uri http://sourceforge.net/projects/tkimg]
[list_end]
