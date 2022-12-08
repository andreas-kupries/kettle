
[//000000001]: # (kettle \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> &#124; <a
href="../../toc.md">Main Table Of Contents</a> &#124; <a
href="../toc.md">Table Of Contents</a> &#124; <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle \- Kettle \- Core

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [Overview](#section2)

  - [Build declarations](#section3)

  - [Graphical Interface Support](#section4)

  - [Tool handling](#section5)

  - [Recursive invokations](#section6)

  - [Option database](#section7)

  - [Option Types and Validation](#section8)

  - [Path utilities](#section9)

  - [Recipe database](#section10)

  - [Status management](#section11)

  - [IO virtualization](#section12)

  - [General Utilities](#section13)

      - [Anonymous procedures](#subsection1)

      - [Error handling](#subsection2)

      - [String processing](#subsection3)

  - [License](#section14)

  - [Bugs, Ideas, Feedback](#section15)

  - [Keywords](#keywords)

  - [Category](#category)

# <a name='synopsis'></a>SYNOPSIS

package require Tcl 8\.5  

[__kettle tcl__](#1)  
[__kettle tclapp__ *path*](#2)  
[__kettle critcl3__](#3)  
[__kettle depends\-on__ *path*\.\.\.](#4)  
[__kettle doc\-destination__ *path*](#5)  
[__kettle doc__ ?*docroot*?](#6)  
[__kettle figures__ ?*figroot*?](#7)  
[__kettle gh\-pages__](#8)  
[__kettle testsuite__ ?*testroot*?](#9)  
[__kettle gui__ __make__](#10)  
[__kettle tool__ __declare__ *names* ?*validator*?](#11)  
[__kettle tool__ __get__ *name*](#12)  
[__kettle__ __invoke__](#13)  
[__kettle option__ __define__](#14)  
[__kettle option__ __onchange__](#15)  
[__kettle option__ __no\-work\-key__](#16)  
[__kettle option__ __exists__](#17)  
[__kettle option__ __names__](#18)  
[__kettle option__ __help__](#19)  
[__kettle option__ __set__](#20)  
[__kettle option__ __set\-default__](#21)  
[__kettle option__ __set\!__](#22)  
[__kettle option__ __unset__](#23)  
[__kettle option__ __get__](#24)  
[__kettle option__ __type__](#25)  
[__kettle option__ __save__](#26)  
[__kettle option__ __load__](#27)  
[__kettle option__ __config__](#28)  
[__kettle ovalidate__ __enum__](#29)  
[__kettle ovalidate__ __any__](#30)  
[__kettle ovalidate__ __string__](#31)  
[__kettle ovalidate__ __boolean__](#32)  
[__kettle ovalidate__ __listsimple__](#33)  
[__kettle ovalidate__ __directory__](#34)  
[__kettle ovalidate__ __readable\.file__](#35)  
[__kettle ovalidate__ __path__](#36)  
[__kettle path__ __bench\-file__ *path*](#37)  
[__kettle path__ __bindir__ ?*path*?](#38)  
[__kettle path__ __cat__ *path* *arg*\.\.\.](#39)  
[__kettle path__ __cathead__ *path* *n* *arg*\.\.\.](#40)  
[__kettle path__ __copy\-file__ *src* *dstdir*](#41)  
[__kettle path__ __copy\-files__ *dstdir* *arg*\.\.\.](#42)  
[__kettle path__ __critcl3\-package\-file__ *file*](#43)  
[__kettle path__ __diagram\-file__ *path*](#44)  
[__kettle path__ __doctools\-file__ *path*](#45)  
[__kettle path__ __dry\-barrier__ ?*dryscript*?](#46)  
[__kettle path__ __exec__ *arg*\.\.\.](#47)  
[__kettle path__ __fixhashbang__ *file* *shell*](#48)  
[__kettle path__ __foreach\-file__ *path* *pv* *script*](#49)  
[__kettle path__ __grep__ *pattern* *data*](#50)  
[__kettle path__ __htmldir__ ?*path*?](#51)  
[__kettle path__ __in__ *path* *script*](#52)  
[__kettle path__ __incdir__ ?*path*?](#53)  
[__kettle path__ __install\-application__ *src* *dstdir*](#54)  
[__kettle path__ __install\-file\-group__ *label* *dstdir* *arg*\.\.\.](#55)  
[__kettle path__ __install\-file\-set__ *label* *dstdir* *arg*\.\.\.](#56)  
[__kettle path__ __install\-script__ *src* *dstdir* *shell*](#57)  
[__kettle path__ __kettle\-build\-file__ *path*](#58)  
[__kettle path__ __libdir__ ?*path*?](#59)  
[__kettle path__ __mandir__ ?*path*?](#60)  
[__kettle path__ __norm__ *path*](#61)  
[__kettle path__ __pipe__ *lv* *script* *arg*\.\.\.](#62)  
[__kettle path__ __relative__ *base* *dst*](#63)  
[__kettle path__ __relativecwd__ *dst*](#64)  
[__kettle path__ __relativesrc__ *dst*](#65)  
[__kettle path__ __remove\-path__ *base* *path*](#66)  
[__kettle path__ __remove\-paths__ *base* *arg*\.\.\.](#67)  
[__kettle path__ __rgrep__ *pattern* *data*](#68)  
[__kettle path__ __scan__ *label* *root* *predicate*](#69)  
[__kettle path__ __script__](#70)  
[__kettle path__ __set\-executable__ *path*](#71)  
[__kettle path__ __sourcedir__ ?*path*?](#72)  
[__kettle path__ __strip__ *path* prefix](#73)  
[__kettle path__ __tcl\-package\-file__ *file*](#74)  
[__kettle path__ __tcltest\-file__ *path*](#75)  
[__kettle path__ __tmpfile__ ?*prefix*?](#76)  
[__kettle path__ __uninstall\-application__ *src* *dstdir*](#77)  
[__kettle path__ __uninstall\-file\-group__ *label* *dstdir*](#78)  
[__kettle path__ __uninstall\-file\-set__ *label* *dstdir* *arg*\.\.\.](#79)  
[__kettle path__ __write__ *path* *contents* *arg*\.\.\.](#80)  
[__kettle recipe__ __define__](#81)  
[__kettle recipe__ __parent__](#82)  
[__kettle recipe__ __exists__](#83)  
[__kettle recipe__ __names__](#84)  
[__kettle recipe__ __help__](#85)  
[__kettle recipe__ __run__](#86)  
[__kettle status__ __begin__](#87)  
[__kettle status__ __fail__](#88)  
[__kettle status__ __ok__](#89)  
[__kettle status__ __is__](#90)  
[__kettle status__ __save__](#91)  
[__kettle status__ __load__](#92)  
[__kettle status__ __clear__](#93)  
[__kettle io__ __setwidget__ *w*](#94)  
[__kettle io__ __for\-gui__ *script*](#95)  
[__kettle io__ __for\-terminal__ *script*](#96)  
[__kettle io__ __puts__ *arg*\.\.\.](#97)  
[__kettle io__ __trace__ *text*](#98)  
[__kettle io__ __trace\-on__](#99)  
[__kettle io__ __animation begin__](#100)  
[__kettle io__ __animation write__ *text*](#101)  
[__kettle io__ __animation indent__ *text*](#102)  
[__kettle io__ __animation last__ *text*](#103)  
[__kettle io__ *tag* *script*](#104)  
[__kettle io__ m*tag* *text*](#105)  
[__lambda__ *arguments* *body* ?*arg*\.\.\.?](#106)  
[__lambda@__ *namespace* *arguments* *body* ?*arg*\.\.\.?](#107)  
[__try__ *arg*\.\.\.](#108)  
[__kettle strutil__ __indent__ *text* *prefix*](#109)  
[__kettle strutil__ __padl__ *list*](#110)  
[__kettle strutil__ __padr__ *list*](#111)  
[__kettle strutil__ __reflow__ *text* ?*prefix*?](#112)  
[__kettle strutil__ __undent__ *text*](#113)  

# <a name='description'></a>DESCRIPTION

Welcome to Kettle, an application and set of packages providing support for the
easy building and installation of pure Tcl packages, and
[Critcl](https://github\.com/andreas\-kupries/critcl) based Tcl packages\.

Please read the document *[Kettle \- Introduction to
Kettle](kettle\_intro\.md)*, if you have not done so already, to get an
overview of the whole system\.

This document is the reference to all commands provided by the kettle package,
from the user\-visible declarations to the lowest utilities\.

It is intended for both power\-users wishing to write their own high\-level
commands linking into the existing foundations and developers and maintainers of
kettle itself\.

A basic user should read *[Kettle \- Application \- Build
Interpreter](kettle\_app\.md)* and *[Kettle \- Build
Declarations](kettle\_dsl\.md)* instead\.

# <a name='section2'></a>Overview

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
Each component C is generally served by a single ensemble command,
"__kettle__ __C__"\. The exceptions are the components exporting the
user\-visible declaration commands\. Their commands, while still named
"__kettle__ __C__", are not ensembles, but the one command in that
component\.

The following sections go through the components from the top down to the
bottom, starting with the user visible commands described in *[Kettle \- Build
Declarations](kettle\_dsl\.md)*, covering all the green boxes\. For the
remainder:

  - gui

    [Graphical Interface Support](#section4)

  - tool

    [Tool handling](#section5)

  - invoke

    [Recursive invokations](#section6)

  - option

    [Option database](#section7)

  - ovalidate

    [Option Types and Validation](#section8)

  - path

    [Path utilities](#section9)

  - recipe

    [Recipe database](#section10)

  - status

    [Status management](#section11)

  - io

    [IO virtualization](#section12)

  - lambda

    [Anonymous procedures](#subsection1)

  - try

    [Error handling](#subsection2)

  - strutil

    [String processing](#subsection3)

Not convered in the above is "standard\.tcl"\. This file does not export any
commands to document\. It unconditionally defines the standard recipes instead\.
These are the recipes which are always available, in contrast to the recipes
dynamically created by the declarations commands in response to their scanning
of a package source directory\.

# <a name='section3'></a>Build declarations

  - <a name='1'></a>__kettle tcl__

    This command declares the presence of one or more Tcl packages in the
    package source directory\.

    The package source directory is scanned to locate them\. Packages are
    detected by finding a marker \(Tcl command\) of the form

        package provide NAME VERSION

    in a file, where both __NAME__ and __VERSION__ must be literal
    strings, not commands, nor variable references\. It is best recognized when
    found alone on its line\. Note that files containing an *anti\-marker* of
    the form

        package require critcl

    are rejected as Tcl packages\. Use the command __kettle critcl3__ to
    detect such packages, mixing Tcl and C\. In each accepted package file the
    command further looks for and recognizes embedded pragmas of the form

        # @owns: PATH

    which provides kettle with information about files belonging to the same
    package without directly providing it\. This can be data files, or other Tcl
    files sourced by the main package file\.

    For each detected package __P__ two recipes are defined, to install and
    uninstall this package, namely:

      * __install\-package\-__P____

      * __uninstall\-package\-__P____

    The command further extends the recipes

      * __install\-tcl\-packages__

      * __install\-packages__

      * __install__

      * __uninstall\-tcl\-packages__

      * __uninstall\-packages__

      * __uninstall__

    generating a recipe tree matching

        install
        -> install-packages
           -> install-tcl-packages
              -> install-app-$path

        uninstall
        -> uninstall-packages
           -> uninstall-tcl-packages
              -> uninstall-app-$path

    The extended recipes may be created by this process\. As other declarations
    create similar trees these get merged together, enabling a user to install
    parts of the sources at various levels of specifity, from just a specific
    package up to all and sundry\.

    Tcl packages are installed into the directory specified by option
    __\-\-lib\-dir__ despite technically not being binary files\.

      * __\-\-lib\-dir__ path

        This configuration option specifies the path to the directory packages
        \(binary and script\) will be installed into\.

        The default value is the \[__info library__\] directory of the
        __tclsh__ used to run the __kettle__ application\.

        If the option __\-\-exec\-prefix__ is modified the default value
        changes to "__\-\-exec\-prefix__/lib"\.

    To simplify usage the command heuristically detects documentation and
    testsuites by means of internally calling the commands __kettle doc__
    and __kettle testsuite__ with default path arguments \("doc" and "tests"
    respectively\)\.

    If documentation and/or testsuite are placed in non\-standard locations these
    commands have to be run before __kettle tcl__, with the proper paths\.

    If dependencies have been specified, via __kettle depends\-on__, the
    package specific install and debug recipes will recusively invoke install or
    debug on them before building the package itself\.

  - <a name='2'></a>__kettle tclapp__ *path*

    This command declares the presence of a Tcl script application found at the
    *path* under the package source directory\.

    If the specified application is found the command will define two recipes to
    install and uninstall this application, namely:

      * __install\-app\-*path*__

      * __uninstall\-app\-*path*__

    It will further extend the recipes

      * __install\-tcl\-applications__

      * __install\-applications__

      * __install__

      * __uninstall\-tcl\-applications__

      * __uninstall\-applications__

      * __uninstall__

    generating a recipe tree matching

        install
        -> install-applications
           -> install-tcl-applications
              -> install-app-$path

        uninstall
        -> uninstall-applications
           -> uninstall-tcl-applications
              -> uninstall-app-$path

    The extended recipes may be created by this process\. As other declarations
    create similar trees these get merged together, enabling a user to install
    parts of the sources at various levels of specifity, from just a specific
    application up to all and sundry\.

    Script applications are installed into the directory specified by option
    __\-\-bin\-dir__ despite technically not being binary files\.

      * __\-\-bin\-dir__ path

        This configuration option specifies the path to the directory
        applications \(binary and script\) will be installed into\.

        The default value is the directory of the __tclsh__ used to run the
        __kettle__ application\.

        If the option __\-\-exec\-prefix__ is modified the default value
        changes to "__\-\-exec\-prefix__/bin"\.

  - <a name='3'></a>__kettle critcl3__

    This command declares the presence of one or more critcl\-based Tcl packages
    in the package source directory, mixing C and Tcl\.

    The package source directory is scanned to locate them\. Packages are
    detected by finding two markers \(Tcl commands\) in the file\. These markers
    are of the form

        package provide NAME VERSION

    and

        package require critcl

    Both __NAME__ and __VERSION__ must be literal strings, not commands,
    nor variable references\. They are best recognized when found alone on their
    respective lines\.

    For each detected package __P__ three recipes are defined, to install
    and uninstall this package\. Installation comes in two variants, regular and
    debug:

      * __install\-package\-__P____

      * __debug\-package\-__P____

      * __uninstall\-package\-__P____

    The command further extends the recipes

      * __install\-binary\-packages__

      * __install\-packages__

      * __install__

      * __debug\-binary\-packages__

      * __debug\-packages__

      * __debug__

      * __uninstall\-binary\-packages__

      * __uninstall\-packages__

      * __uninstall__

    generating a recipe tree matching

        install
        -> install-packages
           -> install-binary-packages
              -> install-app-$path

        debug
        -> debug-packages
           -> debug-binary-packages
              -> debug-app-$path

        uninstall
        -> uninstall-packages
           -> uninstall-binary-packages
              -> uninstall-app-$path

    The extended recipes may be created by this process\. As other declarations
    create similar trees these get merged together, enabling a user to install
    parts of the sources at various levels of specifity, from just a specific
    package up to all and sundry\.

    Critcl\-based packages are installed into the directory specified by option
    __\-\-lib\-dir__\. Critcl's choice of the target configuration to build for
    can be overrriden via option __\-\-target__\. Kettle's choice of which
    critcl application to use cane overriden by option __\-\-with\-critcl3__,
    except if kettle found a __critcl__ package and runs everything itself
    instead of invoking critcl child processes\.

      * __\-\-lib\-dir__ path

        This configuration option specifies the path to the directory packages
        \(binary and script\) will be installed into\.

        The default value is the \[__info library__\] directory of the
        __tclsh__ used to run the __kettle__ application\.

        If the option __\-\-exec\-prefix__ is modified the default value
        changes to "__\-\-exec\-prefix__/lib"\.

      * __\-\-target__ string

        The value of this option is the target name __critcl__ should use to
        build C code\.

        The default value is the empty string, leaving the choice of target to
        __critcl__ itself\.

      * __\-\-with\-critcl3__ path

        This configuration option specifies the path to the tool __critcl3__
        for the compilation and installation of critcl\-based C code\.

        The default value is the path to the first of

          1. "critcl3",

          1. "critcl3\.kit",

          1. "critcl3\.tcl",

          1. "critcl3\.exe",

          1. "critcl",

          1. "critcl\.kit",

          1. "critcl\.tcl", and

          1. "critcl\.exe"

        found on the __PATH__\. None of these matter however should the
        system find the package __critcl__ version 3 or higher among the
        packages known to the __tclsh__ running the __kettle__
        application\. In that case kettle will run everything in itself, without
        invoking critcl child processes\.

    To simplify usage the command heuristically detects documentation and
    testsuites by means of internally calling the commands __kettle doc__
    and __kettle testsuite__ with default path arguments \("doc" and "tests"
    respectively\)\.

    If documentation and/or testsuite are placed in non\-standard locations these
    commands have to be run before __kettle critcl3__, with the proper
    paths\.

    If dependencies have been specified, via __kettle depends\-on__, the
    package specific install and debug recipes will recusively invoke install or
    debug on them before building the package itself\.

  - <a name='4'></a>__kettle depends\-on__ *path*\.\.\.

    This command declares that the current sources depend on the packages in the
    specified directories\. These are best specified as relative directories and
    most useful in package bundles where multiple dependent packages are managed
    in a single source repository\.

    The arguments can be paths to files too\. In that case the files are assumed
    to be the build declaration files of the required packages in question\. In
    case of a directory path kettle will search for the build declaration file
    it needs\. This information is currently only used by the package\-specific
    "install" and "debug" recipes generated by the kettle commands __kettle
    tcl__ and __kettle critcl__\.

  - <a name='5'></a>__kettle doc\-destination__ *path*

    The "doc" recipe generated by the __kettle doc__ command \(see below\)
    saves the conversion results into the sub\-directory specified by option
    __\-\-with\-doc\-destination__\.

    This command declares that the results should be put into the specified
    non\-standard *path* instead of the default of "embedded"\. To take effect
    it has to be run *before* __kettle doc__ is run\. *Note* that the
    user is still able to override with by setting
    __\-\-with\-doc\-destination__ on the command line\.

      * __\-\-with\-doc\-destination__ path

        This configuration option specifies the path to the directory the
        generated documentation should be placed into for the documentation
        installa recipes to pick up from\.

        This should be a relative path, which will interpreted relative to the
        package source directory\.

        The default value is "embedded"\.

        A build declaration file can override this default with the __kettle
        doc\-destination__ command\.

  - <a name='6'></a>__kettle doc__ ?*docroot*?

    This command declares the presence of __doctools__\-based documentation
    files under the directory *docroot*, which is a path relative to the
    source directory\.

    If not specified *docroot* defaults to "doc"\.

    While this command can be invoked multiple times, only the first invokation
    will have an effect\. Every invokation after that is ignored\. The commands
    __kettle tcl__, __kettle critcl3__, and __kettle gh\-pages__ run
    this command implicitly, with the default paths\. This means that if
    documentation is stored in a non\-standard location __kettle doc__ must
    be run explicitly before them, with the proper path\.

    The package documentation directory is scanned to locate the documentation
    files\. They are recognized by containing any of the marker strings

      * "__\[manpage\_begin__"

      * "__\-\-\- doctools \-\-\-__"

      * "__tcl\.tk//DSL doctools//EN//__"

    in their first 1024 characters\. Possible documentation files are rejected
    should they contain any of the anti\-markers

      * "__\-\-\- \!doctools \-\-\-__"

      * "__\!tcl\.tk//DSL doctools//EN//__"

    in their first 1024 characters\. This last is necessary as doctools include
    file feature allows the actual document content to start in an include file
    which cannot operate without being includes from a master file configuring
    it\.

    When documentation files are found the command will define recipes to
    convert the documentation into manpages and HTML files, plus recipes install
    the conversion results\. The conversion results themselves are stored as
    specified by __kettle doc\-destination__ \(see above\) and associated
    options\.

      * __doc__

      * __install\-doc\-html__

      * __install\-doc\-manpages__

      * __uninstall\-doc\-html__

      * __uninstall\-doc\-manpages__

    The command further extends the recipes

      * __install\-doc__

      * __install__

      * __uninstall\-doc__

      * __uninstall__

    generating a recipe tree matching

        install
        -> install-doc
           -> install-doc-html
           -> install-doc-manpages

        uninstall
        -> uninstall-doc
           -> uninstall-doc-html
           -> uninstall-doc-manpages

    The extended recipes may be created by this process\. As other declarations
    create similar trees these get merged together, enabling a user to install
    parts of the sources at various levels of specifity, from just a specific
    type of documentation up to all and sundry\.

    HTML documentation is stored under the directory specified by option
    __\-\-html\-dir__\. Manpages are stored under the directory specified by
    option __\-\-man\-dir__\. The "doc" recipe uses the __dtplite__
    application to perform the various conversions\.

      * __\-\-html\-dir__ path

        This configuration option specifies the path to the directory package
        documentation in HTML format will be installed into\.

        The default value is "__\-\-prefix__/html"\.

      * __\-\-man\-dir__ path

        This configuration option specifies the path to the directory package
        documentation \(manpages, in \*roff format\) will be installed into\.

        The default value is "__\-\-prefix__/man"\.

      * __\-\-with\-dtplite__ path

        This configuration option specifies the path to the tool __dtplite__
        for doctools\-based documentation processing\.

        The default value is the path to the first of "dtplite", "dtplite\.kit",
        "dtplite\.tcl", and "dtplite\.exe" found on the __PATH__\.

    To simplify usage the command heuristically detects tklib/diagram based
    figures by means of internally calling the command __kettle figures__
    with default path arguments \("__doc\-sources__/figures\}"\.

    If the figures are placed in a non\-standard location this command has to be
    run before __kettle doc__, with the proper paths\.

  - <a name='7'></a>__kettle figures__ ?*figroot*?

    This command declares the presence of __diagram__\-based figures under
    the directory *figroot*, which is a path relative to the source directory\.

    If not specified *figroot* defaults to "doc/figures"\.

    While this command can be invoked multiple times, only the first invokation
    will have an effect\. Every invokation after that is ignored\. The command
    __kettle doc__ \(and indirectly __kettle tcl__ and __kettle
    critcl3__\) runs this command implicitly, with the default paths\. This
    means that if diagrams are stored in a non\-standard location __kettle
    figures__ must be run explicitly before them, with the proper path\.

    The package diagram directory is scanned to locate the diagram files\. They
    are recognized by containing the marker string

      * "__tcl\.tk//DSL diagram//EN//__"

    in their first 1024 characters\.

    When diagram files are found the command will define recipes to convert the
    diagrams into PNG raster images \(saved as siblings to their source files\),
    and to render the diagrams on a Tk canvas\.

      * __figures__

      * __show\-figures__

    The recipes use the __dia__ application \(of __tklib__\) to perform
    the conversions, and GUI rendering\.

      * __\-\-with\-dia__ path

        This configuration option specifies the path to the tool __dia__ for
        tklib/diagram\-based diagram processing\.

        The default value is the path to the first of "dia", "dia\.kit",
        "dia\.tcl", and "dia\.exe" found on the __PATH__\.

  - <a name='8'></a>__kettle gh\-pages__

    This command declares the presence of a *gh\-pages* branch in the
    repository, as is used by, for example,
    [https://github\.com](https://github\.com), to manage the web\-site for a
    project in the repository of the project\.

    The command confirms the presence of documentation and that the local
    repository is __git__\-based\. If neither is true nothing done\.

    While this command can be invoked multiple times, only the first invokation
    will have an effect\. Every invokation after that is ignored\. It runs the
    command __kettle doc__ command implicitly, with the default paths, to
    ensure that its own check for documentation work properly\. This means that
    if documentation is stored in a non\-standard location __kettle doc__
    must be run explicitly before this command, with the proper path\.

    When the above tests pass the command will define a recipe named
    __gh\-pages__, which performs all the automatable steps to copy the
    embedded documentation of the project into its *gh\-pages* branch\.
    Afterward the checkout is left at the *gh\-pages* branch, for the user to
    review and commit\. While the last step could be automated the review cannot,
    making the point moot\.

  - <a name='9'></a>__kettle testsuite__ ?*testroot*?

    This command declares the presence of a __tcltest__\-based testsuite
    under the directory *testroot*, which is a path relative to the source
    directory\.

    If not specified *testroot* defaults to "tests"\.

    While this command can be invoked multiple times, only the first invokation
    will have an effect\. Every invokation after that is ignored\. The commands
    __kettle tcl__ and __kettle critcl3__\) run this command implicitly,
    with the default paths\. This means that if a testsuite is stored in a
    non\-standard location __kettle testsuite__ must be run explicitly before
    them, with the proper path\.

    The package testsuite directory is scanned to locate the test files\. They
    are recognized by containing the marker string

      * "__tcl\.tk//DSL tcltest//EN//__"

    in their first 1024 characters\.

    When testsuites are found the command will define a recipe to run them\. This
    recipe will recursively invoke the recipes "debug" \(or "install" if the
    former does not exist, or fails\) before performing the tests, installing the
    package under test \(and its dependencies\) in a local directory for use by
    the testsuites\. The supporting commands provided by kettle \(see *[Kettle \-
    Testsuite Support](kettle\_test\.md)*\) know how to use this\.

      * __test__

    The verbosity of testsuite output to the terminal is specified by the option
    __\-\-log\-mode__\. The ability to save testsuite output to a series of
    files is specified by the option __\-\-log__\. The tclsh shell used for
    running the testsuites is specified by option __\-\-with\-shell__\.

      * __\-\-log\-mode__ compact&#124;full

        An option for recipe 'test', if defined\. Its value determines the
        verbosity of test suite information printed to the terminal or log
        window\.

        The default is __compact__\.

      * __\-\-log__ path

        An option for recipe 'test', if defined\. Its value is the path "stem"
        for a series of files testsuite information is saved into\. The actual
        files use the specified stem and add their specifc file extension to it\.

        The default is the empty string, disabling the saving of testsuite
        information\.

      * __\-\-with\-shell__ path

# <a name='section4'></a>Graphical Interface Support

This layer contains the command for the creation of the standard graphical
interface to the system\.

  - <a name='10'></a>__kettle gui__ __make__

    This high\-level command creates a standard graphical interface providing
    access to all options and defined recipes, through two tabs in a notebook\.

    Options are handled by type specific fields, the details of which are
    created by the option type definitions found under __kettle ovalidate__,
    as specified in section [Option Types and Validation](#section8)\.

    Recipes are acessible through one button per recipe\.

    Output is written to a text widget acting as a log window, in the same tab
    which contains the action buttons\.

# <a name='section5'></a>Tool handling

This layer contains commands to manage the declaration of a dependency on
external comands, and their use\.

  - <a name='11'></a>__kettle tool__ __declare__ *names* ?*validator*?

    This command declares the need for an external tool which can have any of
    the listed *names*\. The first element of that list is the name the tool
    will be known under within kettle, also called the *primary name* of the
    tool\. This is the name to hand to __kettle tool get__ below to retrieve
    the tool's location\.

    Similarly the primary name is used to define an option named
    \-\-with\-__name__, used to hold the path found by searching for the tool
    on the __PATH__ under its various names, and to allow the user to
    override kettle's choice\.

    If *validator* is specified it will be treated as the body of an anonymous
    procedure with a single argument *cmd*, the path of the tool found on
    __PATH__ and returning a boolean value telling the caller if this path
    is acceptable \(result == __true__\), or not\. In case of the latter the
    system will continue searching with the next name in *names*\.

  - <a name='12'></a>__kettle tool__ __get__ *name*

    This command returns the path to the *name*d tool, assuming that it was
    __declare__d before\. If no such tool is specified the command prints an
    error message and aborts the execution of the current recipe and its
    callers\.

# <a name='section6'></a>Recursive invokations

The commands of this layer enable recipes to recursively invoke other recipes,
for the current and in other packages\.

  - <a name='13'></a>__kettle__ __invoke__

# <a name='section7'></a>Option database

This layer manages the option database, which both holds the configuration
options, their definitions and values, as also named shared global state\.

  - <a name='14'></a>__kettle option__ __define__

  - <a name='15'></a>__kettle option__ __onchange__

  - <a name='16'></a>__kettle option__ __no\-work\-key__

  - <a name='17'></a>__kettle option__ __exists__

  - <a name='18'></a>__kettle option__ __names__

  - <a name='19'></a>__kettle option__ __help__

  - <a name='20'></a>__kettle option__ __set__

  - <a name='21'></a>__kettle option__ __set\-default__

  - <a name='22'></a>__kettle option__ __set\!__

  - <a name='23'></a>__kettle option__ __unset__

  - <a name='24'></a>__kettle option__ __get__

  - <a name='25'></a>__kettle option__ __type__

  - <a name='26'></a>__kettle option__ __save__

  - <a name='27'></a>__kettle option__ __load__

  - <a name='28'></a>__kettle option__ __config__

# <a name='section8'></a>Option Types and Validation

This layer defines the validation types usable by the options\.

  - <a name='29'></a>__kettle ovalidate__ __enum__

  - <a name='30'></a>__kettle ovalidate__ __any__

  - <a name='31'></a>__kettle ovalidate__ __string__

  - <a name='32'></a>__kettle ovalidate__ __boolean__

  - <a name='33'></a>__kettle ovalidate__ __listsimple__

  - <a name='34'></a>__kettle ovalidate__ __directory__

  - <a name='35'></a>__kettle ovalidate__ __readable\.file__

  - <a name='36'></a>__kettle ovalidate__ __path__

# <a name='section9'></a>Path utilities

This layer contains the commands \.\.\.

  - <a name='37'></a>__kettle path__ __bench\-file__ *path*

  - <a name='38'></a>__kettle path__ __bindir__ ?*path*?

  - <a name='39'></a>__kettle path__ __cat__ *path* *arg*\.\.\.

  - <a name='40'></a>__kettle path__ __cathead__ *path* *n* *arg*\.\.\.

  - <a name='41'></a>__kettle path__ __copy\-file__ *src* *dstdir*

  - <a name='42'></a>__kettle path__ __copy\-files__ *dstdir* *arg*\.\.\.

  - <a name='43'></a>__kettle path__ __critcl3\-package\-file__ *file*

  - <a name='44'></a>__kettle path__ __diagram\-file__ *path*

  - <a name='45'></a>__kettle path__ __doctools\-file__ *path*

  - <a name='46'></a>__kettle path__ __dry\-barrier__ ?*dryscript*?

  - <a name='47'></a>__kettle path__ __exec__ *arg*\.\.\.

  - <a name='48'></a>__kettle path__ __fixhashbang__ *file* *shell*

  - <a name='49'></a>__kettle path__ __foreach\-file__ *path* *pv* *script*

  - <a name='50'></a>__kettle path__ __grep__ *pattern* *data*

  - <a name='51'></a>__kettle path__ __htmldir__ ?*path*?

  - <a name='52'></a>__kettle path__ __in__ *path* *script*

  - <a name='53'></a>__kettle path__ __incdir__ ?*path*?

  - <a name='54'></a>__kettle path__ __install\-application__ *src* *dstdir*

  - <a name='55'></a>__kettle path__ __install\-file\-group__ *label* *dstdir* *arg*\.\.\.

  - <a name='56'></a>__kettle path__ __install\-file\-set__ *label* *dstdir* *arg*\.\.\.

  - <a name='57'></a>__kettle path__ __install\-script__ *src* *dstdir* *shell*

  - <a name='58'></a>__kettle path__ __kettle\-build\-file__ *path*

  - <a name='59'></a>__kettle path__ __libdir__ ?*path*?

  - <a name='60'></a>__kettle path__ __mandir__ ?*path*?

  - <a name='61'></a>__kettle path__ __norm__ *path*

  - <a name='62'></a>__kettle path__ __pipe__ *lv* *script* *arg*\.\.\.

  - <a name='63'></a>__kettle path__ __relative__ *base* *dst*

  - <a name='64'></a>__kettle path__ __relativecwd__ *dst*

  - <a name='65'></a>__kettle path__ __relativesrc__ *dst*

  - <a name='66'></a>__kettle path__ __remove\-path__ *base* *path*

  - <a name='67'></a>__kettle path__ __remove\-paths__ *base* *arg*\.\.\.

  - <a name='68'></a>__kettle path__ __rgrep__ *pattern* *data*

  - <a name='69'></a>__kettle path__ __scan__ *label* *root* *predicate*

  - <a name='70'></a>__kettle path__ __script__

  - <a name='71'></a>__kettle path__ __set\-executable__ *path*

  - <a name='72'></a>__kettle path__ __sourcedir__ ?*path*?

  - <a name='73'></a>__kettle path__ __strip__ *path* prefix

  - <a name='74'></a>__kettle path__ __tcl\-package\-file__ *file*

  - <a name='75'></a>__kettle path__ __tcltest\-file__ *path*

  - <a name='76'></a>__kettle path__ __tmpfile__ ?*prefix*?

  - <a name='77'></a>__kettle path__ __uninstall\-application__ *src* *dstdir*

  - <a name='78'></a>__kettle path__ __uninstall\-file\-group__ *label* *dstdir*

  - <a name='79'></a>__kettle path__ __uninstall\-file\-set__ *label* *dstdir* *arg*\.\.\.

  - <a name='80'></a>__kettle path__ __write__ *path* *contents* *arg*\.\.\.

# <a name='section10'></a>Recipe database

This layer contains the commands managing the database of all known recipes,
ready for execution\.

  - <a name='81'></a>__kettle recipe__ __define__

  - <a name='82'></a>__kettle recipe__ __parent__

  - <a name='83'></a>__kettle recipe__ __exists__

  - <a name='84'></a>__kettle recipe__ __names__

  - <a name='85'></a>__kettle recipe__ __help__

  - <a name='86'></a>__kettle recipe__ __run__

# <a name='section11'></a>Status management

The command of this layer manage the status of the currently executing recipe
and the database holding the knowledge about all executed recipes, keyed by
their name, location and relevant configuration\. This database is shared among
instances of kettle during recursive invokation\.

  - <a name='87'></a>__kettle status__ __begin__

  - <a name='88'></a>__kettle status__ __fail__

  - <a name='89'></a>__kettle status__ __ok__

  - <a name='90'></a>__kettle status__ __is__

  - <a name='91'></a>__kettle status__ __save__

  - <a name='92'></a>__kettle status__ __load__

  - <a name='93'></a>__kettle status__ __clear__

# <a name='section12'></a>IO virtualization

This section describes the IO virtualization layer used to decouple the higher
layer's output from the actual destination, terminal or gui log window\.

  - <a name='94'></a>__kettle io__ __setwidget__ *w*

    This command sets the text widget to use for output, redirecting all output
    made through __kettle io puts__ and __kettle io trace__ from the
    terminal to this widget\.

  - <a name='95'></a>__kettle io__ __for\-gui__ *script*

  - <a name='96'></a>__kettle io__ __for\-terminal__ *script*

    These two commands execute the script in their calling context if the IO
    system is using text widget or terminal for output, respectively\.

  - <a name='97'></a>__kettle io__ __puts__ *arg*\.\.\.

    This command is an emulation of Tcl's builtin __puts__ which writes to
    either a terminal \(default\), or a text widget\. The latter happens only if
    such a widget was set with __kettle io set\-widget__\.

    The full syntax of the builtin __puts__ is implemented\.

    This redirection affects only the standard channels however, all other
    channels given to the command will go to their proper files, sockets, etc\.

  - <a name='98'></a>__kettle io__ __trace__ *text*

    This command is the tracing of kettle internals\. It will not produce output
    until __kettle io trace\-on__ is invoked\. The specified *text* is run
    through a round of substitution \(in the callers context\), resolving
    variables and commands embedded into it\. This allows the use of
    brace\-quoting, preventing the execution of such embedded commands while
    tracing is disabled\.

  - <a name='99'></a>__kettle io__ __trace\-on__

    This command activates the tracing of internals, enabling __kettle io
    trace__ to produce output\.

  - <a name='100'></a>__kettle io__ __animation begin__

    This command is the first in a group of four implementing the foundations
    for text\-based progress bars and the like\.

    When invoked it initializes the internal state for writing on the last line
    of the terminal without moving into the next line\. This sets the maximum
    column used to __0__, and the current prefix to the empty string\.

  - <a name='101'></a>__kettle io__ __animation write__ *text*

    This command writes the concatenation of the current prefix and input
    *text* to the current line, clearing and then overwriting the previous
    content of the same line\. By writing different texts an animation effect can
    be generated, with only the prefix staying constant\. The command takes care
    to track the largest column characters have been written to and to clear
    them even if the current string does not cover them\.

  - <a name='102'></a>__kettle io__ __animation indent__ *text*

    This command extends the current prefix with *text*\. Nothing else happens\.

  - <a name='103'></a>__kettle io__ __animation last__ *text*

    This command is the last in the group of four handling animation effects\. It
    first __write__s the *text* as usual and then moves the terminal to
    the next line, making *text* the last shown string of the animation and
    that which is kept shown\.

  - <a name='104'></a>__kettle io__ *tag* *script*

    This command activates the color named by *tag*, then executes the
    *script* and lastly resets the output to the standard colors\.

    This means that output generated by IO commands in the script have the
    activated color\. Note that the command does *not* support the nesting of
    color activations\.

    The allowed color tags are:

      * __ok__

      * __warn__

      * __err__

      * __note__

      * __debug__

      * __red__

      * __green__

      * __yellow__

      * __blue__

      * __magenta__

      * __cyan__

      * __white__

  - <a name='105'></a>__kettle io__ m*tag* *text*

    This command is similar to the previous, except that all color tags are
    prefixed with __m__ \(for markup\) and the argument is a string, not a
    script\. The string is extended with color control commands activating and
    deactivating the chosen color at beginning and end, and then returned as the
    result of the command\.

# <a name='section13'></a>General Utilities

This, the lowest layer of the system contains general utility commands for
string processing, anonymous procedures and error handling\.

## <a name='subsection1'></a>Anonymous procedures

  - <a name='106'></a>__lambda__ *arguments* *body* ?*arg*\.\.\.?

  - <a name='107'></a>__lambda@__ *namespace* *arguments* *body* ?*arg*\.\.\.?

    These commands are wrappers around Tcl 8\.5's builtin __apply__ command,
    making the creation of anonymous procedures a bit easier\. Apply uses nested
    lists, the API here flattens that, matching the API of __proc__\.

    The command arguments are like for __proc__, with three exceptions\.

      1. There is no procedure name\. Obviously\.

      1. After the procedure body we can pre\-specify some or all of the
         procedure arguments, i\.e\. perform currying\.

      1. The @\-variant takes the name of the *namespace* the body will be
         executed in\.

## <a name='subsection2'></a>Error handling

  - <a name='108'></a>__try__ *arg*\.\.\.

    This command is an implementation of Tcl 8\.6's try/trap/finally command in
    pure Tcl, providing forward\-compatibility with 8\.6 in this respect\. \(Iit is
    just too useful when it comes to erro handling, especially cleanup of
    transient things like temp files\)\.

    Syntax and semantics fully match the Tcl 8\.6 command\. The code was written
    by Donal Fellows, it is the initial implementation of the builtin, before it
    got re\-implemented in C and byte\-coded\.

## <a name='subsection3'></a>String processing

  - <a name='109'></a>__kettle strutil__ __indent__ *text* *prefix*

    This command splits the input *text* into lines, indents each line using
    the *prefix* and then returns the re\-joined text\.

    Note that the prefix is not applied to empty lines \(containing only
    whitespace\)\. Any whitespace in empty lines is actually completely
    eliminated\.

  - <a name='110'></a>__kettle strutil__ __padl__ *list*

  - <a name='111'></a>__kettle strutil__ __padr__ *list*

    These two commands take a list of strings, compute the maximum length and
    then pads all shorter strings to this length \(using spaces\), returning the
    modified list\. The order of the strings in the result is not changed\. The
    commands differ in where the padding is applied\.

    __padr__ adds the spaces at the end of the string \(to the right\)
    yielding a left\-aligned result\. Whereas __padl__ adds the spaces at the
    beginning of the string \(to the left\) yielding a right\-aligned result\.

    Regardless of the differences, the result is a list of strings of the same
    length\. Useful when having to print a table\. Provide a column of the table
    as input, and the result is properly aligned for printing\.

  - <a name='112'></a>__kettle strutil__ __reflow__ *text* ?*prefix*?

    This command strips empty header and footer lines from the input *text*,
    undents it and then re\-indents using the *prefix*\. If the latter is not
    specified it will default to 4 spaces\.

    The result of all the modifications is then returned as the result of the
    command\.

  - <a name='113'></a>__kettle strutil__ __undent__ *text*

    This command splits the input *text* into lines, computes longest common
    prefix of whitespace over all lines, removes that prefix and then returns
    the re\-joined text\.

    The effect is an un\-indenting of the lines in the *text* which preserves
    the general shape of the left margin\.

    Note that empty lines \(containing only whitespace\) do not take part in the
    prefix calculation\. Any whitespace in empty lines is actually completely
    eliminated\.

# <a name='section14'></a>License

This package, written by Andreas Kupries, is BSD licensed\.

# <a name='section15'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://core\.tcl\-lang\.org/akupries/kettle)\. Please also report any
ideas for enhancements you may have for either package and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#build\_tea)

# <a name='category'></a>CATEGORY

Build support
