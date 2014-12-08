Basics
======
<br/>

Fast alles in ASYD kann via Webinterface konfiguriert werden, das Interface erlaubt das Management der Systeme, Hostgroups, Users, Teams, Monitors sowie Deploy Managements und Deploys selbst.

Monitoring wird von [monit](http://mmonit.com/monit/) auf dem Zielhost übernommen, dieses kommuniziert mit dem ASYD server.

<br/>
Hosts und Hostgroups hinzufügen:
----------------------------
<br/>
Nach dem Login in ASYD ist der erste Schritt die "Server overview" Sektion.
Hier werden existierende Hosts und Hostgroups sowie der jeweilige Serverstatus angezeigt.

Auf der Übersicht können auch Detail Unterseiten der Hosts und Hostgroups aufgerufen und Neustarts ausgeführt werden sowie Hosts und Hostgroups modifiziert und gelöscht werden.

Um einen neuen Server anzulegen wird "Add host" benutzt, die Eingabemaske verlangt nach einem einzigartigen Hostnamem, der Server IP, dem Benutzernamen sowie dem SSH Port und das SSH Passwort.

ASYD installiert dann den ASYD SSH Key in das file ~/.ssh/authorized_keys auf dem Zielhost, das Passwort wird nicht gespeichert.

Alternativ kann das Passwort Feld leer gelassen werden, in diesem Fall wird der ASYD SSH Key zur Authentifizierung verwendet. Vorausgesetzt hierfür ist, dass davor der Public-Key von ASYD (zu finden unter data/ssh_key.pub) auf dem Zielhost unter ~/.ssh/authorized_keys angefügt wird.

Bitte beachte: Wenn ein Host mit nicht root user angelegt wird, muss dieser über "sudo"-Rechte verfügen, sowie keine Passwort Authentifizierung erfolgen.
Dies kann mit dieser Konfigurationszeile in '/etc/sudoers' erfolgen:
'%sudo ALL=(ALL:ALL) NOPASSWD:ALL'

Nach dem Hinzufügen des Hosts wird automatisch das Monitoring Paket im Hintergrund installiert, in dieser Zeit scheint der Host als "not monitored" auf. Sobald das Setup abgeschlossen ist können in der Detailseite des Hosts Systeminformationen eingesehen, custom Variablen angelegt sowie
der monit Status abgerufen werden.

Um eine neue Hostgroup anzulegen, klicke auf "Add group" und die Eingabemaske erscheint, hier ist nur die Eingabe eines unique Namens erforderlich.

Nachdem die hostgroup erstellt wurde können Details abgerufen sowie Servers und custom Variablen 
hinzugefügt werden. Ein host kann in mehreren hostgroups Mitglied sein.

<br/>
Schnellinstallation:
--------------
<br/>

ASYD bietet die Möglichkeit, einzelne Pakete auf Hosts sowie Hostgroups zu installieren. Um dies zu tun gehe in die "Deploys" Sektion und benutze die "Quick Install" option. Es können mit Leerzeichen getrennt mehrere Pakete installiert werden (zB. htop nano vim).

Die Installationsroutine wird von ASYD übernommen, ASYD überprüft hierbei den Host und nutzt den lokalen Paketmanager.
Bitte beachte, dass nicht alle Pakete auf allen Systemen die gleichen Namen tragen.

Bitte lies ebenfalls die [Solaris](solaris.md) Sektion der Dokumentation für mehr Detailinformationen über Solaris/OpenIndiana Systeme.

<br/>
ASYD Datenstruktur:
-------------------
<br/>

  * `asyd.rb - config.ru`: Base Files für ASYD, `asyd.rb` enthält den Basiscode `config.ru` erlaubt Phusion Passenger zu starten und die Applikation zu verwalten.
  * `installer/`: enthält die monit Standardkonfiguration. Dieser Ordner wird nach der Installation gelöscht.
  * `models/`: enthält den ASYD core.
  * `routes/`: enthält die Routes und Aktionen, welche auf den Hosts ausgeführt werden.
  * `views/`: enthält das Webinterface.
  * `static/lib/`: enthält JavaScript, CSS und Bilder für die Views.
  * `data/`: enthält ASYD Daten
    * `data/db/`: SQLite Datenbank Dateien für Hosts, Hostgroups, Users, Teams, Tasks, Notifications, Monitoring Notifications und System Status.
    * `data/deploys/`: Deploy Speicherlokation (Detailinformationen unter [Deploys](deploys.md)).
    * `data/monitors/`: monit Dateien für Service Monitoring.
