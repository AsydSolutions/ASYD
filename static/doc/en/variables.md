Variables
=========
<br/>
ASYD offers a set of global variables, related to the host information, and offers
the possibility of creating your own custom variables (see "[Basics](basics.md) - Adding hosts and Hostgroups"
on the documentation).

You can use any of those variables on any configuration file, deploy definition file, on the
conditions for the conditionals and on the "monitor" files for monitoring services. These variables
will get automatically replaced with their value (unless stated with the "noparse" parameter/tag). All the
variables are case-insensitive, which means `<%IP%>` and `<%ip%>` will return the same value.

<br/>
Global variables:
-----------------
<br/>

    <%ASYD%> - ASYD server IP

    <%HOSTNAME%> - Target host name

    <%IP%> - Target host IP

    <%DIST%> - Target host Linux distribution

    <%DIST_VER%> - Target host distribution version

    <%ARCH%> - Target host architecture

    <%PKG_MANAGER%> - Target host package manager

    <%MONITOR:service%> - Not really a variable, monitors the service 'service'

<br/>
Custom variables:
-----------------
<br/>
You can define custom variables on both hosts and hostgroups. You can also override the value
of a variable defined on a hostgroup by defining the same variable on a host.

    <%VAR:varname%> - Use the value assigned to "varname"
