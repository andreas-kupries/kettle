[subsection {Linenoise Facade}]

This project uses the [package linenoise::facade] package supplied by
the linenoise utilities for higher-level interaction, i.e. shells,
than provided by the plain [package linenoise].

[para] Note that Kettle is fully operational even without these
packages, only some of the more advanced features will be disabled,
i.e.:

[list_begin enumerated]

[enum] [vset PTITLE] will assume a terminal width of 80 columns
instead of automatically adapting the help output to the terminal
width.

[enum] [vset PTITLE] runs only as a regular application within a
terminal and does supply its own shell with interaction and prompts.

[list_end]

[para] This is necessary to break the indirect cycle of build
dependencies through the [package Cmdr] framework.

[para] To get features listed above please install Kettle first, and
then go to either the main repository at
[uri http://core.tcl.tk/akupries/linenoise-utilities]

or the backup at
[uri http://chiselapp.com/andreas_kupries/repositories/linenoise-utilities]

and follow the instructions given at these sites to create a working
installation. They are not repeated here. If there are problems with
these instructions please file a bug against the linenoise-utilities
project, and not [vset PTITLE].

[para]
