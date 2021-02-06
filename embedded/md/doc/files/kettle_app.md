
[//000000001]: # (kettle\_app \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\_app\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\_app\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> | <a
href="../../toc.md">Main Table Of Contents</a> | <a
href="../toc.md">Table Of Contents</a> | <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle\_app \- Kettle \- Application \- Build Interpreter

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [The kettle application](#section2)

  - [Options](#section3)

  - [Standard Recipes](#section4)

  - [build\.tcl Example](#section5)

  - [License](#section6)

  - [Bugs, Ideas, Feedback](#section7)

  - [Keywords](#keywords)

  - [Category](#category)

# <a name='synopsis'></a>SYNOPSIS

package require Tcl 8\.5

[__[kettle](kettle\.md)__ ?__\-f__ *buildfile*? ?__\-trace__? \(*goal*&#124;__\-\-option__ *value*\)\.\.\.](#1)

# <a name='description'></a>DESCRIPTION

Welcome to Kettle, an application and set of packages providing support for the
easy building and installation of pure Tcl packages\.

Please read the document *[Kettle \- Introduction to
Kettle](kettle\_intro\.md)*, if you have not done so already, to get an
overview of the whole system\.

Here we document the kettle application available to a user of kettle, i\.e\. a
package developer using \(or wishing to use\) kettle as the build system for their
code\.

This application resides between the kettle core and the build script written by
the package developer, as shown in the architectural diagram below\.

![](\.\./\.\./image/arch\_app\.png)

For the build \(declaration\) commands available to build scripts based on kettle
see *[Kettle \- Build Declarations](kettle\_dsl\.md)*\.

# <a name='section2'></a>The kettle application

The __[kettle](kettle\.md)__ application is the main interpreter for
build declarations\. It can be used directly, or as a shell in the hash\-bang line
of build files\.

Its general syntax is

  - <a name='1'></a>__[kettle](kettle\.md)__ ?__\-f__ *buildfile*? ?__\-trace__? \(*goal*&#124;__\-\-option__ *value*\)\.\.\.

    In a hash\-bang line for a build file the syntax is 'kettle \-f', with the
    build file becoming the argument to __\-f__, and the arguments to the
    build file then following, starting with the optional __\-trace__\.

    Note: The application will look for a build file "build\.tcl" in the current
    working, if no build file is specified\.

    Configuration options and recipes to run can be mixed on the commandline,
    with the options processed first, and then the recipes\. For this to work all
    the options require a value\.

    The list of known options, help about them, and their state after option
    processing can be queried through the standard recipes __list\-options__,
    __help\-options__, and __show\-configuraton__\.

    The list of known recipes and help about them can be queried through the
    standard recipes __list\-recipes__, and __help\-recipes__\.

    Note that the set of recipes is dynamically constructed based on the scans
    of source directory made by kettle at the direction of the build file\. I\.e\.
    the options on the command line are processed first, then the build file is
    used to scan the sources and initialize the necessary recipes, at last the
    recipes on the command line are run\.

    The application understands one dot\-file for configuration,
    "~/\.kettle/config"\. This file is expected to contain user\-specific standard
    options to use\. Its contents are processed as part of the option processing,
    before the options found on the command line\. For all other extensibility
    the user is reminded that build file are Tcl files, with the full power of
    the language behind them\. Which includes the builtin command __source__\.

    If no recipe is specified on the command line a standard recipe is run\. On
    unix platforms it is "help", whereas on windows "gui" is used\.

# <a name='section3'></a>Options

  - __\-\-bin\-dir__ path

    This configuration option specifies the path to the directory applications
    \(binary and script\) will be installed into\.

    The default value is the directory of the __tclsh__ used to run the
    __[kettle](kettle\.md)__ application\.

    If the option __\-\-exec\-prefix__ is modified the default value changes to
    "__\-\-exec\-prefix__/bin"\.

  - __\-\-color__ boolean

    The value of this configuration option determines if output is colorized or
    not\.

    The default value is platform\-dependent\. On windows the default is
    __off__, disabling colorization\. On unix the default is __on__,
    activating colorization\. Except if it could be determined that the script's
    __stdout__ is not a proper terminal, then the default is __off__\.

    For this last check the system attempts to use the package __Tclx__\. If
    that package is not available then it cannot be determined if __stdout__
    is a proper terminal, thus colorization is active\.

  - __\-\-config__ path

    This is an internal option used by kettle for the communication between
    parent and child instances when handling a recursive invokation\. The
    generated file specified as the value of the option holds the configuration
    of the parent, for the child to read and use\.

  - __\-\-dry__ boolean

    The value of this configuration option determines if \(un\)installation
    modifies the file system \(__off__\) or not \(__on__ == dry run\)\.

    The default value is __off__\. This means that the system will modify the
    file system as instructed by recipes\.

  - __\-\-exec\-prefix__ path

    This configuration option specifies the path to the root directory for all
    platform\-dependent \(binary\) installation files\.

    The default value is "__\-\-prefix__"\.

  - __\-\-html\-dir__ path

    This configuration option specifies the path to the directory package
    documentation in HTML format will be installed into\.

    The default value is "__\-\-prefix__/html"\.

  - __\-\-ignore\-glob__ list

    This option specifies the set of files and directories to ignore during
    directory scans, as a Tcl list of glob patterns to match\.

    The default value is

      1. \*~

      1. \_FOSSIL\_

      1. \.fslckout

      1. \.fos

      1. \.git

      1. \.svn

      1. CVS

      1. \.hg

      1. RCS

      1. SCCS

      1. \*\.bak

      1. \*\.bzr

      1. \*\.cdv

      1. \*\.pc

      1. \_MTN

      1. \_build

      1. \_darcs

      1. \_sgbak

      1. blib

      1. autom4te\.cache

      1. cover\_db

      1. ~\.dep

      1. ~\.dot

      1. ~\.nib

      1. ~\.plst

    matching the special files and directories of various source code control
    systems, the backup files of various editors, and the like\.

  - __\-\-include\-dir__ path

    This configuration option specifies the path to the directory package C
    header files will be installed into\.

    The default value is "__\-\-prefix__/include"\.

  - __\-\-lib\-dir__ path

    This configuration option specifies the path to the directory packages
    \(binary and script\) will be installed into\.

    The default value is the \[__info library__\] directory of the
    __tclsh__ used to run the __[kettle](kettle\.md)__ application\.

    If the option __\-\-exec\-prefix__ is modified the default value changes to
    "__\-\-exec\-prefix__/lib"\.

  - __\-\-log__ path

    An option for recipe 'test', if defined\. Its value is the path "stem" for a
    series of files testsuite information is saved into\. The actual files use
    the specified stem and add their specifc file extension to it\.

    The default is the empty string, disabling the saving of testsuite
    information\.

  - __\-\-log\-mode__ compact&#124;full

    An option for recipe 'test', if defined\. Its value determines the verbosity
    of test suite information printed to the terminal or log window\.

    The default is __compact__\.

  - __\-\-man\-dir__ path

    This configuration option specifies the path to the directory package
    documentation \(manpages, in \*roff format\) will be installed into\.

    The default value is "__\-\-prefix__/man"\.

  - __\-\-prefix__ path

    This configuration option specifies the path to the root directory for all
    platform\-independent \(non\-binary\) installation files\.

    The default value is the twice parent of the \[__info library__\]
    directory of the __tclsh__ used to run the
    __[kettle](kettle\.md)__ application\.

  - __\-\-state__ path

    This is an internal option used by kettle for the communication between
    parent and child instances when handling a recursive invokation\. The
    generated file specified as the value of the option holds the work state of
    the parent, for the child to read and extend\.

  - __\-\-target__ string

    The value of this option is the target name __critcl__ should use to
    build C code\.

    The default value is the empty string, leaving the choice of target to
    __critcl__ itself\.

  - __\-\-verbose__ boolean

    The value of this configuration option determines if tracing of system
    internals is done \(__on__\), or not \(__off__\)\. This is the option
    equivalent of the special flag __\-trace__\.

    The default value is __off__, disabling tracing of internals\.

  - __\-\-with\-doc\-destination__ path

    This configuration option specifies the path to the directory the generated
    documentation should be placed into for the documentation installa recipes
    to pick up from\.

    This should be a relative path, which will interpreted relative to the
    package source directory\.

    The default value is "embedded"\.

    A build declaration file can override this default with the __kettle
    doc\-destination__ command\.

  - __\-\-with\-critcl3__ path

    This configuration option specifies the path to the tool __critcl3__ for
    the compilation and installation of critcl\-based C code\.

    The default value is the path to the first of

      1. "critcl3",

      1. "critcl3\.kit",

      1. "critcl3\.tcl",

      1. "critcl3\.exe",

      1. "critcl",

      1. "critcl\.kit",

      1. "critcl\.tcl", and

      1. "critcl\.exe"

    found on the __PATH__\. None of these matter however should the system
    find the package __critcl__ version 3 or higher among the packages known
    to the __tclsh__ running the __[kettle](kettle\.md)__
    application\. In that case kettle will run everything in itself, without
    invoking critcl child processes\.

  - __\-\-with\-dia__ path

    This configuration option specifies the path to the tool __dia__ for
    tklib/diagram\-based diagram processing\.

    The default value is the path to the first of "dia", "dia\.kit", "dia\.tcl",
    and "dia\.exe" found on the __PATH__\.

  - __\-\-with\-dtplite__ path

    This configuration option specifies the path to the tool __dtplite__ for
    doctools\-based documentation processing\.

    The default value is the path to the first of "dtplite", "dtplite\.kit",
    "dtplite\.tcl", and "dtplite\.exe" found on the __PATH__\.

  - __\-\-with\-shell__ path

# <a name='section4'></a>Standard Recipes

The following recipes are understood by __[kettle](kettle\.md)__
regardless of build definitions\. They are its *standard* recipes\.

  - __gui__

    Opens a standard graphical interface\. This is the standard recipe run on
    windows if no recipe was specified on the command line\.

  - __help\-options__

    Print the help for all known options\.

  - __help\-recipes__

    Print the help for all defined recipes\.

  - __help__

    The combination of the previous two recipes\. This is the standard recipe run
    on unix if no recipe was specified on the command line\.

  - __list\-options__

    Print a list of all known options\.

  - __list\-recipes__

    Print a list of all defined recipes\.

  - __list__

    The combination of the previous two recipes\.

  - __null__

    This recipe does nothing\. It is generally only useful for kettle developers,
    in combination with option __\-trace__\.

  - __show\-configuration__

    Print the state of the option database after processing the dot\-file and
    command line settings\.

  - __show\-state__

    Print the state of various internal global settings after processing the
    dot\-file and command line settings\.

# <a name='section5'></a>build\.tcl Example

A simple example of a build\.tcl script is that for kettle itself\.

Stripping out the special code taking care of the fact that it cannot assume to
have kettle installed already this reduces to the code below, and of that only
the last two lines are relevant in terms of build declarations\. The first three
are the \(bourne\) shell magic to find and run the kettle application in the
__PATH__ environment variable\. \(The actual code assumes that
__[kettle](kettle\.md)__ is found the working directory, again it cannot
assume to be installed already\)\.

    \#\!/bin/sh
    \# \-\*\- tcl \-\*\- \\
    exec kettle \-f "$0" "$\{1\+$@\}"
    kettle tcl
    kettle tclapp kettle

The code asks the system to search for and handle all Tcl script packages to be
found in the directory of the "build\.tcl" file, and declares that we have a
script application named __[kettle](kettle\.md)__ in the same directory\.
As the documentation files and figures are in the standard locations, __kettle
tcl__ is allowed to handle them implicitly\.

Done\.

# <a name='section6'></a>License

This package, written by Andreas Kupries, is BSD licensed\.

# <a name='section7'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://chiselapp\.com/user/andreas\_kupries/repository/Kettle/index)\.
Please also report any ideas for enhancements you may have for either package
and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#key0)

# <a name='category'></a>CATEGORY

Build support
