
[//000000001]: # (kettle\_devguide \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\_devguide\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\_devguide\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> &#124; <a
href="../../toc.md">Main Table Of Contents</a> &#124; <a
href="../toc.md">Table Of Contents</a> &#124; <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle\_devguide \- Kettle \- The Developer's Guide

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [Developing for Kettle](#section2)

      - [Architecture](#subsection1)

      - [Directory structure](#subsection2)

  - [Bugs, Ideas, Feedback](#section3)

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

This document is a guide for developers working on Kettle, i\.e\. maintainers
fixing bugs, extending the functionality of application or package, etc\.

Users of kettle wishing to write their own high\-level commands linking into the
existing foundations should read the *[Kettle \- Core](kettle\.md)* document
instead, as that is the reference manpage to the whole functionality available
to them, and likely enough to get going\.

Please read

  1. *[Kettle \- License](kettle\_license\.md)*,

  1. *[Kettle \- How To Get The Sources](kettle\_sources\.md)*, and

  1. *[Kettle \- The Installer's Guide](kettle\_installer\.md)*

first, if that was not done already\.

Here we assume that the sources are already available in a directory of your
choice, and that you not only know how to build and install them, but also have
all the necessary requisites to actually do so\. The guide to the sources in
particular also explains which source code management system is used, where to
find it, how to set it up, etc\.

# <a name='section2'></a>Developing for Kettle

## <a name='subsection1'></a>Architecture

The high\-level architecture is shown in the image below:

![](\.\./\.\./image/architecture\.png) This document is concerned with the
lowest level shown, the core kettle package itself\. The inner boxes of that
architectural box show the parts which are user\-visible, i\.e\. providing the DSL
commands explained in *[Kettle \- Build Declarations](kettle\_dsl\.md)*\. For
the details we have

![](\.\./\.\./image/pkg\_dependencies\.png) In this image we now see all the
components found inside of the kettle package, their organization into layers
and their dependencies\. The latter is actually a bit simplified, showing only
the dependencies between adjacent layers and leaving out the dependencies
crossing layers\. Adding them would make the image quite a bit more crowded\.

The green boxes are again the user\-visible parts, either for the build
declarations\. The rest is internal\. Note how and that the components found in
the blue box are all dependent on each other, i\.e\. these are in circular
dependencies\.

The names in the boxes directly refer to the file names containing the code of
the component, without the extension, "\.tcl"\. The only file not mentioned is
"kettle\.tcl" which is the entrypoint to the package and sources all the others\.

More information about the functionality made available by each component is
found in *[Kettle \- Core](kettle\.md)*, the reference to all commands\.

## <a name='subsection2'></a>Directory structure

  - Helpers

  - Documentation

      * "doc/"

        This directory contains the documentation sources\. The texts are written
        in *doctools* format, whereas the figures are a mixture of TeX \(math
        formulas\), and tklib's __dia__\(gram\) package and application\.

      * "embedded/"

        This directory contains the documentation converted to regular manpages
        \(nroff\) and HTML\. It is called embedded because these files, while
        derived, are part of the fossil repository, i\.e\. embedded into it\. This
        enables fossil to access and display these files when serving the
        repositories' web interface\. The "Command Reference" link at
        [https://core\.tcl\-lang\.org/akupries/kettle](https://core\.tcl\-lang\.org/akupries/kettle)
        is, for example, accessing the generated HTML\.

  - Package Code, General structure

    See the second image in section [Architecture](#subsection1), and the
    associated explanations\.

# <a name='section3'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://core\.tcl\-lang\.org/akupries/kettle)\. Please also report any
ideas for enhancements you may have for either package and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#build\_tea)

# <a name='category'></a>CATEGORY

Build support
