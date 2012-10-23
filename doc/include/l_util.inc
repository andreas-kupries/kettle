[comment {--- !doctools ---}]
[comment { support :: kettle struutil et. al. :: }]

This, the lowest layer of the system contains general utility commands
for string processing, anonymous procedures and error handling.

[subsection {Anonymous procedures}]

[list_begin definitions]
[call [cmd lambda]]
[call [cmd lambda@]]
[list_end]

[subsection {Error handling}]

[list_begin definitions]
[call [cmd try]]
[list_end]

[subsection {String processing}]

[list_begin definitions]
[call [cmd {kettle strutil}] [method indent]]
[call [cmd {kettle strutil}] [method padl]]
[call [cmd {kettle strutil}] [method padr]]
[call [cmd {kettle strutil}] [method reflow]]
[call [cmd {kettle strutil}] [method undent]]
[list_end]
