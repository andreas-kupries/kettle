[subsection Cmdr]

This project uses the [package Cmdr] package to handle all command
line processing. As this package uses [package [vset PTITLE]],
i.e. ourselves as its build system we now have an obvious circle of
dependencies here, each requiring the other to be installed.

[para] This circle is broken here, by [vset PTITLE]. It comes with a
local copy of the Cmdr framework which is used when Cmdr is not found
in the environment.

[para] The indirect circle through the packages [package linenoise]
and [package linenoise::facade] introduced by Cmdr is also broken by
[vset PTITLE], keeping it operational with a slight degradation of
functionality (no dynamic adaption of help to terminal width, and all
possible interactive prompts and shells of Cmdr disabled).

[para]
