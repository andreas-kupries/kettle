
[//000000001]: # (kettle\_changes \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\_changes\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\_changes\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> &#124; <a
href="../../toc.md">Main Table Of Contents</a> &#124; <a
href="../toc.md">Table Of Contents</a> &#124; <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle\_changes \- Kettle Changes

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [Changes](#section2)

      - [Changes for version 1](#subsection1)

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

This document provides an overview of the changes
__[kettle](kettle\.md)__ underwent from version to version\.

# <a name='section2'></a>Changes

## <a name='subsection1'></a>Changes for version 1

This is the first release of kettle, package and application\. The changes
therefore describe the initial features of the system\.

In detail:

  1. Kettle requires Tcl 8\.5 or higher\. Tcl 8\.4 or less is not supported\.

  1. The application __[kettle](kettle\.md)__ provides standard setup to
     run a file "build\.tcl", specified either explicitly via option __\-f__,
     or implicitly \(current working directory\)\.

     This application can be used as the interpreter of a build declaration file
     as well\. In that case option __\-f__ must be part of the
     __\#\!__\-line\.

  1. The core package __[kettle](kettle\.md)__ manages a database of
     recipes, and provides standard code invoked automatically after the
     processing of the build declarations to show help or run a recipe specified
     on the command line\.

     Standard recipes provide introspection into the list of known recipes, and
     display of general and recipe\-specific help\.

  1. Various utility and support packages providing the commands for the build
     declarations, and implementation helpers\.

     Currently supported are

       1) \(Un\)installation of pure Tcl packages\.

       1) \(Un\)installation of Tcl script applications\.

       1) \(Un\)installation of __critcl__\-based Tcl\+C packages\.

       1) \(Re\)generation and \(un\)installation of \(tcllib\) doctools based
          manpages\.

       1) \(Re\)generation and display of \(tklib\) diagram based figures\.

       1) Execution of __tcltest__\-based testsuites\.

       1) Execution of __tclbench__\-based benchmarks\.

# <a name='section3'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://core\.tcl\-lang\.org/akupries/kettle)\. Please also report any
ideas for enhancements you may have for either package and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#build\_tea)

# <a name='category'></a>CATEGORY

Build support
