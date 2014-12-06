Basics
======
<br/>

Fast alles in ASYD kann via Webinterface konfiguriert werden, das Interface erlaubt das Management der
systeme, hostgroups, users, teams, monitor sowie deploy Management und Deploy selbst.

Monitoring wird von [monit](http://mmonit.com/monit/) auf dem Remotehost übernommen, dieses
kommuniziert mit dem ASYD server.

<br/>
Adding Hosts and Hostgroups:
----------------------------
<br/>
Nach dem Login in ASYD ist der erste Schritt die "Server overview" Sektion.
Hier werden existierende hosts und hostgroups sowie der jeweilige Serverstatus angezeigt.

Auf der Übersicht können auch Detail Unterseiten der hosts und hostgroups aufgerufen werden, 
reboots ausgeführt werden sowie hosts und hostgroups modifiziert und gelöscht werden.

Um einen neuen Server hinzuzufügen wird "Add host" benutzt, die Eingabemaske verlangt
nach einem unique hostname, server IP, user sowie den SSH port und das SSH Passwort.

ASYD fügt dann den ASYD SSH Key in das file ~/.ssh/authorized_keys auf dem Zielhost ein,
das Passwort wird nicht gespeichert.

Alternativ kann das Passwort Feld leer gelassen werden, in diesem Fall wird der ASYD
SSH Key zur Authentifizierung verwendet.

Bitte beachten: Wenn ein host mit nicht root user angelegt wird muss dieser über "sudo"
Rechte verfügen sowie keine Passwort Authentifizierung erfolgen.
Dies kann mit dieser sudo line in '/etc/sudoers' angelegt werden:
'%sudo   ALL=(ALL:ALL) NOPASSWD:ALL'

Nach dem hinzufügen des hosts wird automatisch das monitoring paket im Hintergrund installiert,
in dieser Zeit scheint der host als "not monitored" auf. Sobald das Setup abgeschlossen ist
können in der Detailseite des hosts Systeminformationen eingesehen, custom Variablen angelegt sowie
der monit Status abgerufen werden.

Um eine neue hostgroup hinzuzufügen klicke auf "Add group" und die Eingabemaske erscheint, 
hier ist nur die Eingabe eines unique Namens erforderlich.

Nachdem die hostgroup erstellt wurde können Details abgerufen sowie Servers und custom Variablen 
hinzugefügt werden. Ein host kann in mehreren hostgroups Mitglied sein.

<br/>
Quick Install:
--------------
<br/>

ASYD bietet die Option einzelne Pakete in hosts sowie hostgroups zu installieren.
Um dies zu tun gehe in die "Deploys" Sektion und benutze die "Quick Install" option.
Es können mit Abständen getrennt mehrere Pakete installiert werden (zB. htop nano vim).

Die Installationsroutine wird von ASYD übernommen, ASYD überprüft hierbei den host
und nutzt den lokalen Paketmanager.
Bitte beachten das nicht alle Pakete auf allen Systemen die gleichen Namen tragen.

Bitte lies ebenfalls die [Solaris](solaris.md) Sektion der Dokumentation für mehr Detailinformationen über
Solaris/Openindiana Systeme.

<br/>
ASYD data structure:
-------------------
<br/>

  * `asyd.rb - config.ru`: base files für ASYD, `asyd.rb` enthält den Basiscode `config.ru` erlaubt Phusion Passenger zu starten und die Applikation zu verwalten.
  * `installer/`: enthält die monit Standardkonfiguration. Dieser Ordner wird nach der Installation gelöscht.
  * `models/`: enthält den ASYD core.
  * `routes/`: enthält die routes und Aktionen die auf den hosts ausgeführt werden.
  * `views/`: enthält das Webinterface.
  * `static/lib/`: enthält javascript, css und Bilder für die views.
  * `data/`: speichert ASYD data
    * `data/db/`: SQLite DB Dateien für hosts, hostgroups, users, teams,
    tasks, notifications, monitoring notifications und system status.
    * `data/deploys/`: deploy Speicherlokation (Detailinformationen unter [Deploys](deploys.md)).
    * `data/monitors/`: monit Dateien für service Monitoring.
