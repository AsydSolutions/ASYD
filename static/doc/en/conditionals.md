Conditionals
============
<br/>
Conditionals are used for creating rules for when a command should be executed or a configuration
should be used on a host or hostgroup.

Valid conditions are `==` (equal), `!=` (different), `>=` (greater or equal) and `<=` (lower or equal).
The `>=` and `<=` operators can only be used for numbers. The `==` and `!=` operators can be used both
for strings (text comparison) and numbers.

Several conditionals (as many as you want) can be concatenated using `and` and `or`. They will be
evaluated following a sequencial and logical order (i.e. for `condition1 or condition2`, if the first
condition complies, the second one won't be evaluated).

<br/>
Usage:
------
<br/>
**1. Conditional blocks on "def" files**

Conditionals can be used for defining blocks inside a "def" file that should be executed if a
condition complies. Both the opening tag `if <condition>` and the ending tag `endif` must be
written on a single line with no extra characters but the accepted parameters. Between them you
can write any commands that will be executed only if the condition validates.

*Note: You cannot define conditional blocks inside conditional blocks, but only one at a time.
You can, however, use single line conditionals as described on the next point.*

*Syntax:*

    if <%var%> == value [or|and condition2] [or|and ...]
    [...]
    endif

*Example:*

    if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_VER%> >= 5
    install: package
    exec: some command
    endif

**2. Single commands on "def" files**

Conditionals can be used for single commands inside a "def" file. The standard syntax applies,
and you can also define conditions for concrete commands even inside a conditional block (see above)

*Syntax:*

    exec if <%var%> == value [or|and condition2] [or|and ...]: some command

*Example:*

    install if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_VER%> >= 5: package

**3. Conditional blocks on configuration files**

Conditionals can also be used inside configuration files (see [Configurations](configurations.md) on the documentation)
for defining parts of the configuration file that should be only uploaded to the target server
if the condition complies. The usage is the same as for Conditional blocks on "def" files (see above)
but defined by the tags `<%if condition%>` `<%endif%>`.

*Note: You cannot define conditional blocks inside conditional blocks, but only one at a time.*

*Syntax:*

    <%if <%var%> == value [or|and condition2] [or|and ...]%>
    [...]
    <%endif%>

*Example:*

    <%if <%DIST%> == debian and <%DIST_VER%> == 6%>
    some configuration that applies only to Debian 6
    <%endif%>
    <%if <%DIST%> == debian and <%DIST_VER%> >= 7%>
    some configuration that applies only to Debian 7 or newer
    <%endif%>
    common configuration that applies to all systems
