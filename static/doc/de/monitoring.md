Monitoring
==========
<br/>
Die Überwachung wird von [monit](http://mmonit.com/monit/) übernommen.
Der ASYD Server prüft die host Lokale Monit Instanz auf Änderungen.

<br/>
Set Up
------
<br/>
Die Überwachung wird automatisch mit jedem neuen host installiert.

Dieses Deploy kann im Verzeichnis `data/deploys/monit/` gefunden werden nachdem die Initiale ASYD Installation
abgeschlossen ist.


<br/>
Monitors
--------
<br/>
Monitors sind Standard Monit Konfigurationen für einen einzelnen Service.

Diese Dateien werden im Verzeichnis `data/monitors/` gespeichert und akzeptieren Conditionals sowie Variablen.
Die erlaubt die Benutzung eines einzigen Monitors für jeden/s host OS/Betriebssystem.

Das File muss den gleichnamig dem Service sein, zB. `data/monitors/nginx` für Nginx.

Services können überwacht werden:

1.: Mit dem `monitor` Kommando in einem "def" file"
2.: Mit der Nutzung des `<%MONITOR:service%>` Tags wobei Service dem Monitor Filename entspricht.
