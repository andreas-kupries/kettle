
[//000000001]: # (kettle\_sources \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\_sources\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\_sources\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> &#124; <a
href="../../toc.md">Main Table Of Contents</a> &#124; <a
href="../toc.md">Table Of Contents</a> &#124; <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle\_sources \- Kettle \- How To Get The Sources

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [Source Location](#section2)

  - [Retrieval](#section3)

  - [Source Code Management](#section4)

  - [Bugs, Ideas, Feedback](#section5)

  - [Keywords](#keywords)

  - [Category](#category)

# <a name='synopsis'></a>SYNOPSIS

package require Tcl 8\.5  

# <a name='description'></a>DESCRIPTION

Welcome to Kettle, an application and set of packages providing support for the
easy building and installation of pure Tcl packages, and
[Critcl](https://github\.com/andreas\-kupries/critcl) based Tcl packages\.

Please read the document *[Kettle \- Introduction to
Kettle](kettle\_intro\.md)*, if you have not done so already, to get an
overview of the whole system\.

The audience of this document is anyone wishing to either have just a look at
Kettle's source code, or build the packages, or to extend and modify them\.

For builders and developers we additionally provide

  1. *[Kettle \- License](kettle\_license\.md)*\.

  1. *[Kettle \- The Installer's Guide](kettle\_installer\.md)*\.

  1. *[Kettle \- The Developer's Guide](kettle\_devguide\.md)*\.

respectively\.

# <a name='section2'></a>Source Location

The official repository for Kettle can be found at
[https://core\.tcl\-lang\.org/akupries/kettle](https://core\.tcl\-lang\.org/akupries/kettle),
with mirrors at
[https://chiselapp\.com/user/andreas\_kupries/repository/Kettle](https://chiselapp\.com/user/andreas\_kupries/repository/Kettle)
and
[https://github\.com/andreas\-kupries/kettle](https://github\.com/andreas\-kupries/kettle),
in case of trouble with the main location\.

# <a name='section3'></a>Retrieval

Assuming that you simply wish to look at the sources, or build a specific
revision, the easiest way of retrieving it is to:

  1. Log into this site, as "anonymous", using the semi\-random password in the
     captcha\.

  1. Go to the "Timeline"\.

  1. Choose the revision you wish to have and

  1. follow its link to its detailed information page\.

  1. On that page, choose either the "ZIP" or "Tarball" link to get a copy of
     this revision in the format of your choice\.

# <a name='section4'></a>Source Code Management

For the curious \(or a developer\-to\-be\), the sources are managed by the [Fossil
SCM](https://www\.fossil\-scm\.org)\. Binaries for popular platforms can be found
directly at its [download page](https://www\.fossil\-scm\.org/download\.html)\.

With that tool available the full history of our project can be retrieved via:

> fossil clone [https://core\.tcl\-lang\.org/akupries/kettle](https://core\.tcl\-lang\.org/akupries/kettle) kettle\.fossil

followed by

    mkdir kettle
    cd    kettle
    fossil open ../kettle.fossil

to get a checkout of the head of the trunk\.

# <a name='section5'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://core\.tcl\-lang\.org/akupries/kettle)\. Please also report any
ideas for enhancements you may have for either package and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#build\_tea)

# <a name='category'></a>CATEGORY

Build support
