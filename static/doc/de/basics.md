Basics
======
<br/>

Fast alles in ASYD kann via Webinterface konfiguriert werden, das Interface erlaubt das Management der Systeme, Hostgroups, Users, Teams, Monitors sowie Deploy Managements und Deploys selbst.

Monitoring wird von [monit](http://mmonit.com/monit/) auf dem Zielhost �bernommen, dieses kommuniziert mit dem ASYD server.

<br/>
Hosts und Hostgroups hinzuf�gen:
----------------------------
<br/>
Nach dem Login in ASYD ist der erste Schritt die "Server overview" Sektion.
Hier werden existierende Hosts und Hostgroups sowie der jeweilige Serverstatus angezeigt.

Auf der �bersicht k�nnen auch Detail Unterseiten der Hosts und Hostgroups aufgerufen und Neustarts ausgef�hrt werden sowie Hosts und Hostgroups modifiziert und gel�scht werden.

Um einen neuen Server anzulegen wird "Add host" benutzt, die Eingabemaske verlangt nach einem einzigartigen Hostnamem, der Server IP, dem Benutzernamen sowie dem SSH Port und das SSH Passwort.

ASYD installiert dann den ASYD SSH Key in das file ~/.ssh/authorized_keys auf dem Zielhost, das Passwort wird nicht gespeichert.

Alternativ kann das Passwort Feld leer gelassen werden, in diesem Fall wird der ASYD SSH Key zur Authentifizierung verwendet. Vorausgesetzt hierf�r ist, dass davor der Public-Key von ASYD (zu finden unter data/ssh_key.pub) auf dem Zielhost unter ~/.ssh/authorized_keys angef�gt wird.

Bitte beachte: Wenn ein Host mit nicht root user angelegt wird, muss dieser �ber "sudo"-Rechte verf�gen, sowie keine Passwort Authentifizierung erfolgen.
Dies kann mit dieser Konfigurationszeile in '/etc/sudoers' erfolgen:
'%sudo ALL=(ALL:ALL) NOPASSWD:ALL'

Nach dem Hinzuf�gen des Hosts wird automatisch das Monitoring Paket im Hintergrund installiert, in dieser Zeit scheint der Host als "not monitored" auf. Sobald das Setup abgeschlossen ist k�nnen in der Detailseite des Hosts Systeminformationen eingesehen, custom Variablen angelegt sowie
der monit Status abgerufen werden.

Um eine neue Hostgroup anzulegen, klicke auf "Add group" und die Eingabemaske erscheint, hier ist nur die Eingabe eines unique Namens erforderlich.

Nachdem die hostgroup erstellt wurde k�nnen Details abgerufen sowie Servers und custom Variablen 
hinzugef�gt werden. Ein host kann in mehreren hostgroups Mitglied sein.

<br/>
Schnellinstallation:
--------------
<br/>

ASYD bietet die M�glichkeit, einzelne Pakete auf Hosts sowie Hostgroups zu installieren. Um dies zu tun gehe in die "Deploys" Sektion und benutze die "Quick Install" option. Es k�nnen mit Leerzeichen getrennt mehrere Pakete installiert werden (zB. htop nano vim).

Die Installationsroutine wird von ASYD �bernommen, ASYD �berpr�ft hierbei den Host und nutzt den lokalen Paketmanager.
Bitte beachte, dass nicht alle Pakete auf allen Systemen die gleichen Namen tragen.

Bitte lies ebenfalls die [Solaris](solaris.md) Sektion der Dokumentation f�r mehr Detailinformationen �ber Solaris/OpenIndiana Systeme.

<br/>
ASYD Datenstruktur:
-------------------
<br/>

  * `asyd.rb - config.ru`: Base Files f�r ASYD, `asyd.rb` enth�lt den Basiscode `config.ru` erlaubt Phusion Passenger zu starten und die Applikation zu verwalten.
  * `installer/`: enth�lt die monit Standardkonfiguration. Dieser Ordner wird nach der Installation gel�scht.
  * `models/`: enth�lt den ASYD core.
  * `routes/`: enth�lt die Routes und Aktionen, welche auf den Hosts ausgef�hrt werden.
  * `views/`: enth�lt das Webinterface.
  * `static/lib/`: enth�lt JavaScript, CSS und Bilder f�r die Views.
  * `data/`: enth�lt ASYD Daten
    * `data/db/`: SQLite Datenbank Dateien f�r Hosts, Hostgroups, Users, Teams, Tasks, Notifications, Monitoring Notifications und System Status.
    * `data/deploys/`: Deploy Speicherlokation (Detailinformationen unter [Deploys](deploys.md)).
    * `data/monitors/`: monit Dateien f�r Service Monitoring.
