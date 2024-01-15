
[//000000001]: # (kettle\_dsl \- Kettle \- The Quick Brew System)
[//000000002]: # (Generated from file 'kettle\_dsl\.man' by tcllib/doctools with format 'markdown')
[//000000003]: # (kettle\_dsl\(n\) 1 doc "Kettle \- The Quick Brew System")

<hr> [ <a href="../../../../../../home">Home</a> &#124; <a
href="../../toc.md">Main Table Of Contents</a> &#124; <a
href="../toc.md">Table Of Contents</a> &#124; <a
href="../../index.md">Keyword Index</a> ] <hr>

# NAME

kettle\_dsl \- Kettle \- Build Declarations

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [Build commands](#section2)

  - [License](#section3)

  - [Bugs, Ideas, Feedback](#section4)

  - [Keywords](#keywords)

  - [Category](#category)

# <a name='synopsis'></a>SYNOPSIS

package require Tcl 8\.5 9  

[__kettle tcl__](#1)  
[__kettle tclapp__ *path*](#2)  
[__kettle critcl3__](#3)  
[__kettle depends\-on__ *path*\.\.\.](#4)  
[__kettle doc\-destination__ *path*](#5)  
[__kettle doc__ ?*docroot*?](#6)  
[__kettle figures__ ?*figroot*?](#7)  
[__kettle gh\-pages__](#8)  
[__kettle testsuite__ ?*testroot*?](#9)  

# <a name='description'></a>DESCRIPTION

Welcome to Kettle, an application and set of packages providing support for the
easy building and installation of pure Tcl packages, and
[Critcl](https://github\.com/andreas\-kupries/critcl) based Tcl packages\.

Please read the document *[Kettle \- Introduction to
Kettle](kettle\_intro\.md)*, if you have not done so already, to get an
overview of the whole system\.

Here we document the build \(declaration\) commands available to a user of kettle,
i\.e\. a package developer using \(or wishing to use\) kettle as the build system
for their code\.

These commands are provided by the kettle core, as shown in the architectural
diagram below\.

![](\.\./\.\./image/arch\_core\.png)

# <a name='section2'></a>Build commands

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
        __tclsh__ used to run the __[kettle](kettle\.md)__
        application\. In code:

            set libdir [info library]

        An exception is made if the __info library__ result refers to a zip
        archive instead of disk\. In that case the default value is the "lib"
        directory which is sibling to the "bin" directory containing the
        __tclsh__ used to run the __[kettle](kettle\.md)__
        application\. In code:

            set libdir [file join [file dirname [file dirname [info nameofexecutable]]] lib]

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
        __[kettle](kettle\.md)__ application\.

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
        __tclsh__ used to run the __[kettle](kettle\.md)__
        application\. In code:

            set libdir [info library]

        An exception is made if the __info library__ result refers to a zip
        archive instead of disk\. In that case the default value is the "lib"
        directory which is sibling to the "bin" directory containing the
        __tclsh__ used to run the __[kettle](kettle\.md)__
        application\. In code:

            set libdir [file join [file dirname [file dirname [info nameofexecutable]]] lib]

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
        packages known to the __tclsh__ running the
        __[kettle](kettle\.md)__ application\. In that case kettle will
        run everything in itself, without invoking critcl child processes\.

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

# <a name='section3'></a>License

This package, written by Andreas Kupries, is BSD licensed\.

# <a name='section4'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such at the [Kettle
Tracker](https://core\.tcl\-lang\.org/akupries/kettle)\. Please also report any
ideas for enhancements you may have for either package and/or documentation\.

# <a name='keywords'></a>KEYWORDS

[build tea](\.\./\.\./index\.md\#build\_tea)

# <a name='category'></a>CATEGORY

Build support
