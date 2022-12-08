
[//000000001]: # (kettle\_test \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\_test\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\_test\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> &#124; <a
href="../../toc.md">Main Table Of Contents</a> &#124; <a
href="../toc.md">Table Of Contents</a> &#124; <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle\_test \- Kettle \- Testsuite Support

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [License](#section2)

  - [Bugs, Ideas, Feedback](#section3)

  - [Keywords](#keywords)

  - [Category](#category)

# <a name='synopsis'></a>SYNOPSIS

package require Tcl 8\.5  

[__::kt__ __source__ *path*](#1)  
[__::kt__ __source\*__ *pattern*](#2)  
[__::kt__ __find__ *pattern*](#3)  
[__::kt__ __check__ *name* *version*](#4)  
[__::kt__ __require__ *type* *name* *arg*\.\.\.](#5)  
[__::kt__ __local__ *type* *name* *arg*\.\.\.](#6)  
[__::kt__ __dictsort__ *dict*](#7)  

# <a name='description'></a>DESCRIPTION

Welcome to Kettle, an application and set of packages providing support for the
easy building and installation of pure Tcl packages, and
[Critcl](https://github\.com/andreas\-kupries/critcl) based Tcl packages\.

Please read the document *[Kettle \- Introduction to
Kettle](kettle\_intro\.md)*, if you have not done so already, to get an
overview of the whole system\.

  - <a name='1'></a>__::kt__ __source__ *path*

    This command sources the file specified by the *path*\. In contrast to the
    builtin __::source__ command, this resolves relative paths relative to
    the __tcltest::testsDirectory__\.

  - <a name='2'></a>__::kt__ __source\*__ *pattern*

    This command sources all files found in the __tcltest::testsDirectory__
    and matching the pattern\.

  - <a name='3'></a>__::kt__ __find__ *pattern*

    This command returns a list of all files found in the
    __tcltest::testsDirectory__ and matching the pattern\.

  - <a name='4'></a>__::kt__ __check__ *name* *version*

    This command assumes that the package *name* is present, and verifies that
    we are using at least the specified *version*\. If not the command aborts
    the testsuite in a manner kettle's test controller can detect and respond
    to\.

    This is useful for checking the versions of the Tcl core and/or tcltest\.
    *Note* that the whole of kettle assumes to be run under at least Tcl 8\.5,
    and having tcltest 2 available\.

  - <a name='5'></a>__::kt__ __require__ *type* *name* *arg*\.\.\.

    This command is a wrapper around Tcl's builtin __package require__ which
    aborts the testsuite in a manner kettle's test controller can detect and
    respond to if the specified *external* package is not found\.

    The *type* can be one of __support__, or __testing__, indicating
    the use of the package in the testsuite, i\.e\. a supporting package, or the
    package under test itself\. Exactly one package should have this type\.

  - <a name='6'></a>__::kt__ __local__ *type* *name* *arg*\.\.\.

    This command is like __kt require__ above, except its search of packages
    is restricted to the local packages provided by the test controller, which
    should be the package under test, and its local dependencies, if any\.

  - <a name='7'></a>__::kt__ __dictsort__ *dict*

    This command takes a Tcl dictionary, sorts its contents by its keys
    \(__lsort \-dict__\), and returns the sorted dictionary\.

    This is useful to impose a canonical order on dictionary and array results
    whose natural order can change between Tcl versions, or package revisions\.

# <a name='section2'></a>License

This package, written by Andreas Kupries, is BSD licensed\.

# <a name='section3'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://core\.tcl\-lang\.org/akupries/kettle)\. Please also report any
ideas for enhancements you may have for either package and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#build\_tea)

# <a name='category'></a>CATEGORY

Build support
