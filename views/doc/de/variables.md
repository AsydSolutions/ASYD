Variablen
=========
<br/>
ASYD bietet Globale Variablen mit host Informationen und bietet ebenfalls die Option
eigene Variablen zu definieren. (siehe "[Basics](basics.md)

Jede dieser Variablen kann in jedem Deploy, Konfigurationsfile, in Conditionals und in "monitor" Files benutzt werden.
(Ausnahme: noparse tag)
 Alle Variablen sind case-insensitive was meint das `<%IP%>` und `<%ip%>` die gleiche Ausgabe erzeugen.

<br/>
Globale Variablen:
-----------------
<br/>

    <%ASYD%> - ASYD server IP

    <%HOSTNAME%> - Ziel host name

    <%IP%> - Ziel host IP

    <%DIST%> - Ziel host linux distribution

    <%DIST_VER%> - Ziel host distribution version

    <%ARCH%> - Ziel host architecture

    <%PKG_MANAGER%> - Ziel host package manager

    <%MONITOR:service%> - Keine echte Variable, Überwacht den Service "service"

<br/>
Custom Variablen:
-----------------
<br/>
Eigene Variablen können sowohl in hosts als auch in hostgroups definiert werden.
Hostgroup Variablen können vom host überschrieben werden indem eine gleichnamige Variable angelegt wird.

