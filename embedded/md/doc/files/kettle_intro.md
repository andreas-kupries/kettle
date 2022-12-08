
[//000000001]: # (kettle\_introduction \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\_intro\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\_introduction\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> &#124; <a
href="../../toc.md">Main Table Of Contents</a> &#124; <a
href="../toc.md">Table Of Contents</a> &#124; <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle\_introduction \- Kettle \- Introduction to Kettle

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [Related Documents](#section2)

  - [System Architecture](#section3)

  - [Bugs, Ideas, Feedback](#section4)

  - [Keywords](#keywords)

  - [Category](#category)

# <a name='synopsis'></a>SYNOPSIS

package require Tcl 8\.5  

# <a name='description'></a>DESCRIPTION

Welcome to Kettle, an application and set of packages providing support for the
easy building and installation of pure Tcl packages, and
[Critcl](https://github\.com/andreas\-kupries/critcl) based Tcl packages\.
Kettle is a system to make building Tcl packages quick and easy\. More
importantly, possibly, to make writing the build system for Tcl packages easy\.

As such kettle is several things:

  1. A DSL helping you to write build systems for your packages\.

  1. A package implementing this DSL\.

  1. An application which can serve as the interpreter for a build file
     containing commands in the above DSL\.

All of these will be explained in the documentation, although not everything is
for everybody\. I\.e\. a user of the DSL requires a different set of knowledge than
a developer working on extending kettle's DSL, etc\.

# <a name='section2'></a>Related Documents

  1. *[Kettle \- License](kettle\_license\.md)*\.

  1. *[Kettle \- How To Get The Sources](kettle\_sources\.md)*\.

  1. *[Kettle \- The Installer's Guide](kettle\_installer\.md)*\.

  1. *[Kettle \- The Developer's Guide](kettle\_devguide\.md)*\.

# <a name='section3'></a>System Architecture

The image below provides a basic overview of the system's architecture, with a
package's custom build file at the top, using DSL commands from core layer,
under the mediation of the kettle application\.

![](\.\./\.\./image/architecture\.png)

The manpages relevant to a user of kettle, i\.e\. to a package developer wishing
to use it as the build system for her code are:

  1. *[Kettle \- Application \- Build Interpreter](kettle\_app\.md)*

  1. *[Kettle \- Build Declarations](kettle\_dsl\.md)*

  1. *Kettle \- Testsuite support*

For the developers and maintainers of kettle, and power users wishing to extend
the system to handle their custom circumstances, we additionally have:

  1. *[Kettle \- The Developer's Guide](kettle\_devguide\.md)*

  1. *[Kettle \- Core](kettle\.md)*

# <a name='section4'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://core\.tcl\-lang\.org/akupries/kettle)\. Please also report any
ideas for enhancements you may have for either package and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#build\_tea)

# <a name='category'></a>CATEGORY

Build support
