
[//000000001]: # (kettle\_install\_guide \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\_installer\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\_install\_guide\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> &#124; <a
href="../../toc.md">Main Table Of Contents</a> &#124; <a
href="../toc.md">Table Of Contents</a> &#124; <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle\_install\_guide \- Kettle \- The Installer's Guide

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [Requisites](#section2)

      - [Tcl](#subsection1)

      - [Tclx](#subsection2)

      - [Tk](#subsection3)

      - [Tklib](#subsection4)

      - [tcltest](#subsection5)

  - [Build & Installation Instructions](#section3)

      - [Build & Installation \(Unix\)](#subsection6)

      - [Build & Installation \(Windows\)](#subsection7)

      - [Build & Installation \(Help\)](#subsection8)

  - [Bugs, Ideas, Feedback](#section4)

  - [Keywords](#keywords)

  - [Category](#category)

# <a name='synopsis'></a>SYNOPSIS

package require Tcl 8\.5 9  

# <a name='description'></a>DESCRIPTION

Welcome to Kettle, an application and set of packages providing support for the
easy building and installation of pure Tcl packages, and
[Critcl](https://github\.com/andreas\-kupries/critcl) based Tcl packages\.

Please read the document *[Kettle \- Introduction to
Kettle](kettle\_intro\.md)*, if you have not done so already, to get an
overview of the whole system\.

The audience of this document is anyone wishing to build the packages, for
either themselves, or others\.

For a developer intending to extend or modify the packages we additionally
provide

  1. *[Kettle \- License](kettle\_license\.md)*\.

  1. *[Kettle \- The Developer's Guide](kettle\_devguide\.md)*\.

Please read *[Kettle \- How To Get The Sources](kettle\_sources\.md)* first,
if that was not done already\. Here we assume that the sources are already
available in a directory of your choice\.

# <a name='section2'></a>Requisites

Before Kettle can be build and used a number of requisites must and/or should be
installed\. These are:

  1. The scripting language Tcl\. This requisite is mandatory\. For details see
     [Tcl](#subsection1)\.

  1. The package __tcltest__\. This requisite is optional\. For details see
     [tcltest](#subsection5)\.

  1. The package __Tclx__\. This requisite is optional\. For details see
     [Tclx](#subsection2)\.

  1. The packages __Tk__, __widget::scrolledwindow__,
     __widget::listsimple__, and __widget::dialog__\. These requisites
     are optional\. For details see [Tk](#subsection3) and
     [Tklib](#subsection4)\.

This list assumes that the machine where Kettle is to be installed is
essentially clean\. Of course, if parts of the dependencies listed below are
already installed the associated steps can be skipped\. It is still recommended
to read their sections though, to validate that the dependencies they talk about
are indeed installed\.

## <a name='subsection1'></a>Tcl

As we are building a Tcl package and application it should be pretty much
obvious that a working installation of Tcl itself is needed, and I will not
belabor the point\.

Out of the many possibilites use whatever you are comfortable with, as long as
it provides Tcl 8\.5, or higher\. This may be a Tcl installation provided by your
operating system distribution, from a distribution\-independent vendor, or built
by yourself\.

Myself, I used \(and still use\) [ActiveState](https://www\.activestate\.com)'s
[ActiveTcl](https://www\.activestate\.com/activetcl) 8\.5 distribution during
development, as I am most familiar with it\.

*\(Disclosure: I, Andreas Kupries, worked for ActiveState* *until 2015,
maintaining ActiveTcl and TclDevKit for them\)\.*

This distribution can be found at
[ActiveTcl](https://www\.activestate\.com/activetcl)\. Retrieve the archive of
ActiveTcl 8\.5 for your platform and install it as directed by ActiveState\.

Assuming that ActiveTcl got installed I usually run the command

    teacup update

to install all packages ActiveState provides, and the kitchensink, as the
distribution itself usually contains only the most important set of packages\.
This ensures that the dependencies for Kettle are all present, and more\.

If that is not your liking you have to read the other sections about Kettle's
dependencies to determine the exact set of packages required, and install only
these using

    teacup install $packagename

Both __teacup__ commands above assume that ActiveState's TEApot repository
at [https://teapot\.activestate\.com](https://teapot\.activestate\.com) is in
the list of repositories accessible to __teacup__\. This is automatically
ensured for the ActiveTcl distribution\. Others may have to run

    teacup archive add http://teapot.activestate.com

to make this happen\.

For those wishing to build and install Tcl on their own, the relevant sources
can be found at

  - Tcl

    [https://core\.tcl\-lang\.org/tcl](https://core\.tcl\-lang\.org/tcl)

together with the necessary instructions on how to build it\.

If there are problems with building, installing, or using Tcl please file a bug
against Tcl, or the vendor of your distribution, and not Kettle\.

## <a name='subsection2'></a>Tclx

The __Tclx__ package is an optional requisite of Kettle\. If it is not
installed/available to Kettle it will continue to work, with features depending
on Tclx disabled\.

The only feature using __Tclx__ is the colorization of output, or rather,
the code determining if Kettle should produce colorized output by default, or
not\.

Without __Tclx__ kettle will \(on unix platforms\) always produce colorized
output by default\. With __Tclx__ available kettle will use it to check if
__stdout__ is connected to a proper terminal and disable colorized output by
default if not\.

Now that enough information is available to decide whether Tclx should be used
in your environment or not, the information on how to get the package\.

Out of the many possibilites for getting Tclx \(OS vendor, os\-independent vendor,
building from sources\) use whatever you are comfortable with\.

For myself, I am most comfortable with using
[ActiveState](https://www\.activestate\.com)'s
[ActiveTcl](https://www\.activestate\.com/activetcl) distribution and TEApot\.

See the previous section \([Tcl](#subsection1)\) for disclosure and
information on how to get it\.

Assuming that ActiveTcl got installed running the command

    teacup install Tclx

will install Tclx for your platform, if you have not done the more inclusive

    teacup update

to get everything and the kitchensink\.

For those wishing to build and install Tclx on their own, the relevant sources
can be found at

  - Tclx

    [https://sourceforge\.net/projects/tclx](https://sourceforge\.net/projects/tclx)

together with the necessary instructions on how to build it\.

If there are problems with building, installing, or using Tclx please file a bug
against Tclx, or the vendor of your distribution, and not Kettle\.

## <a name='subsection3'></a>Tk

Kettle's "gui" recipe requires Tk, obviously, and three packages found in Tklib
\(see next section\)\. If Tk or the other packages are not installed the "gui"
recipe cannot be used, and attempting to do so will fail\.

Beyond that however the rest of Kettle will be fully functional\.

Out of the many possibilites for getting Tk use whatever you are comfortable
with, as long as it provides Tk 8\.5, or higher \(we use the themed widgets, and
Tcl 8\.5 is our base\)\. This may be a Tk package provided by your operating system
distribution, from a distribution\-independent vendor, or built by yourself\.

Myself, I used \(and still use\) [ActiveState](https://www\.activestate\.com)'s
[ActiveTcl](https://www\.activestate\.com/activetcl) 8\.5 distribution during
development, as I am most familiar with it\.

See the previous section \([Tcl](#subsection1)\) for disclosure and
information on how to get it\.

Assuming that ActiveTcl got installed Tk will be installed as well\.

For or those wishing to build and install Tk on their own, the relevant sources
can be found at

  - Tk

    [https://core\.tcl\-lang\.org/tk](https://core\.tcl\-lang\.org/tk)

together with the necessary instructions on how to build it\.

If there are problems with building, installing, or using Tk please file a bug
against Tk, or the vendor of your distribution, and not Kettle\.

## <a name='subsection4'></a>Tklib

Kettle's "gui" recipe requires the following three packages found in Tklib\. If
Tk or these packages are not installed the "gui" recipe cannot be used, and
attempting to do so will fail\.

  1. __widget::scrolledwindow__

  1. __widget::listsimple__

  1. __widget::dialog__

Beyond that however the rest of Kettle will be fully functional\.

Out of the many possibilites for getting Tclx \(OS vendor, os\-independent vendor,
building from sources\) use whatever you are comfortable with\. Well, mostly\. The
package __widget::listsimple__ currently exists only in the CVS repository
of Tklib \(location at the end of the section\), and in ActiveState's TEApot\.

For myself, I am most comfortable with using
[ActiveState](https://www\.activestate\.com)'s
[ActiveTcl](https://www\.activestate\.com/activetcl) distribution and TEApot\.

See the previous section \([Tcl](#subsection1)\) for disclosure and
information on how to get it\.

Assuming that ActiveTcl got installed running the commands

    teacup install widget::scrolledwindow
    teacup install widget::listsimple
    teacup install widget::dialog

will install them for your platform, if you have not done the more inclusive

    teacup update

to get everything and the kitchensink\.

For those wishing to build and install Tklib on their own, the relevant sources
can be found at

  - Tcllib

    [https://core\.tcl\-lang\.org/tcllib](https://core\.tcl\-lang\.org/tcllib)

  - Tklib

    [https://core\.tcl\-lang\.org/tklib](https://core\.tcl\-lang\.org/tklib)

together with the necessary instructions on how to build it\.

If there are problems with building, installing, or using Tklib and its packages
please file a bug against Tklib, or the vendor of your distribution, and not
Kettle\.

## <a name='subsection5'></a>tcltest

Kettle's "test" recipe requires the __tcltest__ package\. If this package is
not installed the "test" recipe cannot be used, and attempting to do so will
fail\.

Note however that the sources of tcltest come with a source distribution of Tcl
and the package should always be installed together with Tcl itself\.

If there are problems with using tcltest please file a bug against Tcl, or the
vendor of your Tcl distribution, and not Kettle\.

# <a name='section3'></a>Build & Installation Instructions

## <a name='subsection6'></a>Build & Installation \(Unix\)

This section describes the actions required to install Kettle on Unix systems
\(Linux, BSD, and related, including OS X\)\. If you have to install Kettle on a
Windows machine see section [Build & Installation \(Windows\)](#subsection7)
instead\.

To install Kettle simply run

    /path/to/tclsh8.5 /path/to/kettle/build.tcl install

where "/path/to/tclsh8\.5" is the tclsh of your Tcl installation, and
"/path/to/kettle" the location of the Kettle sources on your system\.

This will build the package and application and then places them into
directories where the __tclsh8\.5__ will find them\. Note that the installed
kettle application is modified to use the chosen tclsh instead of searching for
one on the __PATH__\.

The build system provides a small GUI for those not comfortable with the command
line\. This GUI is accessible by invoking "build\.tcl" without any arguments\.

To get help about the methods of "build\.tcl", and their complete syntax, invoke
"build\.tcl" with argument __help__, i\.e\., like

    /path/to/tclsh8.5 /path/to/kettle/build.tcl help

## <a name='subsection7'></a>Build & Installation \(Windows\)

This section describes the actions required to install Kettle on Windows\(tm\)
systems\. If you have to install Kettle on a Unix machine \(Linux, BSD, and
related, including OS X\) see section [Build & Installation
\(Unix\)](#subsection6) instead\.

To install Kettle simply run

    /path/to/tclsh8.5 /path/to/kettle/kettle -f /path/to/kettle/build.tcl install

where "/path/to/tclsh8\.5" is the tclsh of your Tcl installation, and
"/path/to/kettle" the location of the Kettle sources on your system\. Please note
that and how we are using the non\-installed __[kettle](kettle\.md)__
application found in the sources to install itself\.

This will build the package and application and then places them into
directories where the __tclsh8\.5__ will find them\. Note that the installed
kettle application is modified to use the chosen tclsh instead of searching for
one on the __PATH__\.

The above is written without assuming any associations from extensions \(like
"\.tcl"\) to executables responsible for the file with that extension\. Actually,
given that "build\.tcl" is technically a "kettle"\-script, which in turn is a
"\.tcl"\-script I am not sure if Windows is able to handle such a chain of
interpreters\. The command given above simply spells out the entire chain\.

The build system provides a small GUI for those not comfortable with the command
line\. This GUI is accessible by invoking "build\.tcl" without any arguments from
the command line\.

To get help about the methods of "build\.tcl", and their complete syntax, invoke
"build\.tcl" with argument __help__, i\.e\., like

    /path/to/tclsh8.5 /path/to/kettle/kettle -f /path/to/kettle/build.tcl help

## <a name='subsection8'></a>Build & Installation \(Help\)

Kettle commands for getting various types of help are:

  1. help\-recipes

  1. help\-options

  1. help

  1. list\-recipes

  1. list\-options

  1. list

  1. show\-configuration

# <a name='section4'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://core\.tcl\-lang\.org/akupries/kettle)\. Please also report any
ideas for enhancements you may have for either package and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#build\_tea)

# <a name='category'></a>CATEGORY

Build support
