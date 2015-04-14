Conditionals
============
<br/>
Conditionals werden für die Regel Erstellung von Kommandos oder Konfigurationen in host und hostgroups benutzt.


Valide Conditionals sind `==` (gleich), `!=` (unterschiedlich), `>=` (mehr oder gleich) and `<=` (weniger oder gleich).
Die `>=` und `<=` können nur mit Nummern benutzt werden. Die `==` und `!=` können sowohl für Nummern als auch für Strings
verwendet werden.

Mehrere Conditionals (unbeschränkte Anzahl) können mit 'and' und 'or' verbunden werden.
Diese werden in sequenzieller logischer Reihenfolge ausgeführt, zB. für `condition1 or condition1` wird die
sekundäre Command nicht ausgeführt wenn die Erste erfolgreich ausgeführt wurde.


<br/>
Benutzung:
------
<br/>
**1. Conditional Blöcke in "def" files**

Conditionals können für die Definition von Blöcken in einem "def" file benutzt werden das bei erfolgreicher
Ausführung einer Condition ausgeführt wird.

Sowohl das opening tag `if <condition>` und ending tag `endif` müssen in einer Zeile stehen.
Zwischen den Tags kann jedes Kommando benutzt werden, dies wird nur bei erfolgreicher Ausführung der Conditional ausgeführt.

*Anmerkung: Es können keine Conditional Blöcke in einem Conditional Block verwendet werden.


*Syntax:*

    if <%var%> == value [or|and condition2] [or|and ...]
    [...]
    endif

*Beispiel:*

    if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_ver%> >= 5
    install: package
    exec: ein Kommando
    endif

**2. Single commands in "def" files**

Conditionals können für einzelne Kommandos in einem "def" file verwendet werden. Die Standard Syntax wird hierbei angewendet.


*Syntax:*

    exec if <%var%> == value [or|and condition2] [or|and ...]: some command

*Beispiel:*

    install if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_ver%> >= 5: package

**3. Conditional Blöcke in Konfigurationsdateien**

Conditionals können ebenso in Konfigurationsdateien (siehe [Configurations](configurations.md)) verwendet werden um zB.
nur bei erfolgreicher Ausführung Kommandos auszuführen.


*Anmerkung: Es können keine Conditional Blöcke in einem Conditional Block verwendet werden.

*Syntax:*

    <%if <%var%> == value [or|and condition2] [or|and ...]%>
    [...]
    <%endif%>

*Beispiel:*

    <%if <%DIST%> == debian and <%DIST_VER%> == 6%>
    Konfiguration nur auf Debian 6
    <%endif%>
    <%if <%DIST%> == debian and <%DIST_VER%> >= 7%>
    Konfiguration nur auf Debian 7 und neuer
    <%endif%>
    Konfiguration für alle Systeme
