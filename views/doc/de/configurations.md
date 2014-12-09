Configurations
==============
<br/>

Konfigurationsdateien sind ein Kernstück von ASYD; jede Datei oder Ordner kann im "configs" Verzeichnis eines Deploys gespeichert 
und mit einem "def" File hochgeladen werden.

Jede Konfigurationsdatei wird geparst um Variablen und Conditionals auszufüllen/führen.
Dies erfolgt rekursiv.

Dies kann Global mit dem "noparse" Parameter im def File deaktiviert werden, hierzu werden diese Tags benutzt:
`<%noparse%>` `<%/noparse%>` 

Conditionals können ebenso in Konfigurationsdateien verwendet werden um nur Teile Host oder Hostgroup spezifisch zu benutzen/verteilen.
Dies geschieht über die `<%if condition%>` `<%endif%>` Tags.
Conditionals in einem noparse Block werden nicht ausgeführt.

**WICHTIG:** Bitte beachte das die Spezialkommandos (noparse sowie conditionals) in einer Zeile stehen müssen um korrekt zu 
funktionieren.

    <%noparse%>
    Nicht geparst
    <%/noparse%>
    Rest der Datei

*Bitte lies ebenfalls die [Variables](variables.md) sowie die [Conditionals](conditionals.md) Sektion der Dokumentation für weitere Informationen. 