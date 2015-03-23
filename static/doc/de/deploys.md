Deploys
=======
<br/>
Ein "Deploy" ist eine Sammlung von ausführbaren Kommandos und Kofigurationen die eine automatische 
Installation und Deinstallation sowie den Kofigurations Parse/Upload, Externe Kommandos, Monitoring
und weitere Funktionen mit einem einzigen Klick ermöglichen.


Deploys werden im Verzeichnis "data/deploys/" der ASYD Installation gespeichert.

<br/>
Deploy Struktur:
-----------------
<br/>

* Ein Verzeichnis mit Namen des Deploys (zB. `data/deploys/LAMP/`), dieser wird im Webinterface verwenden.
* Ein "def" file (zB. `data/deploys/LAMP/def`) mit den Definitionen des Deploys -
Pakete zur installation, Konfigurationsupload, Conditionals etc.
* Optional ein "def.sudo" file (zB. `data/deploys/LAMP/def.sudo`) wenn alles als Root ausgeführt werden soll, 
auch wenn im host ein unpriviligierter Benutzer verwendet wird
* Optional ein "undeploy" file (zB. `data/deploys/LAMP/undeploy`) mit den Schritten zur Rückgängigmachung/Deinstallation.
* Optional ein "undeploy.sudo" file (zB. `data/deploys/LAMP/undeploy.sudo`), das undeploy equivalent zu def.sudo.
* Ein "configs" Verzeichnis mit Konfigurationsdateien und Ordnern zum Upload auf den Zielhost
(zB. `data/deploys/LAMP/configs/apache/apache.conf`).

**Notiz über "def.sudo":** Diese wird nur ausgeführt wenn am host kein root User vorhanden ist. Dies ist zB. für Ubuntu gedacht.
Sofern dieses File nicht vorhanden ist wird das Normale def File als unpriviligierter Benutzer ausgeführt.

<br/>
Das "def" File:
------------------
<br/>
Sowohl def als auch def.sudo und undeploy/undeploy.sudo akzeptieren die folgenden Parameter und Kommandos. 


*Bitte beachte der Doppelpunkt - : - nach der Conditionals vor den/dem Kommando(s) ist nötig.

**0. Kommentare**

Jede Zeile mit einem Hashtag Prefix '#' wird als Kommentar interpretiert und nicht ausgeführt.
Ein Spezialkommentar ist zur Ausgabe eines Alarms/Notiz verfügbar, dies ist zB. als Warnung vor Abhängigkeiten nutzbar.
Dies wird via `# alert:` implementiert.

*Syntax:* `# Normaler Kommentar`

*Syntax:* `#  alert: Warnung zur Anzeige vor Deploy start`

**1. install**

Das install Kommando kann benutzt werden um eine Leerzeichen getrennte Liste von Paketen die auf dem host installiert werden
sollen zu erstellen.
 

Intern prüft ASYD welches OS/Betriebssystem auf dem host installiert ist und nutzt den jeweiligen Paketmanager.


Optional können Conditionals benutzt werden, siehe hierzu [Conditionals](conditionals.md).

Auf Solaris Systemen wird ebenso ein Extra Parameter zur Auswahl des Paketmanagers unterstützt, siehe hierzu
[Solaris](solaris.md) 


*Syntax:* `install [if <condition>]: package_a package_b package_c`

**2. uninstall**

Das uninstall Kommando funktioniert essentiell wie das install Kommando nur zur Entfernung.
Auf Solaris Systemen wird wieder ebenso ein Extra Parameter zur Auswahl des Packagemanagers unterstützt, siehe hierzu
[Solaris](solaris.md) 

*Syntax:* `uninstall [if <condition>]: package_a package_b package_c`

**3. config file**

Dieses Kommando erlaubt den Upload von Konfigurationsdateien und Ordner die im "configs" Verzeichnis
des Deploys gespeichert werden, der zweite Parameter ist das Zielfile am host.

Optional werden auch Conditionals sowie noparse Tags unterstützt.
Bitte lese ebenfalls [Configurations](configurations.md).

*Syntax:* `[noparse] config file [if <condition>]: file.conf, /destination/file.conf`

**4. config dir**

Funktioniert gleich dem config file Kommando nur Rekursiv für alle Unterverzeichnisse und Dateien.


Optional werden auch Conditionals sowie noparse Tags unterstützt.

*Syntax:* `[noparse] config dir [if <condition>]: confdir, /destination/dir`

**5. exec**

Dieses Kommando führt das definierte Kommando am host aus, deswegen handelt es sich um das am 
mächtigste Kommando in ASYD.
Exec akzeptiert ebenfalls Conditionals sowie einen host parameter der Bestimmung auf welchem host es ausgeführt werden soll,
dies übergeht die Deploy Einstellung.
Dies kann zB. für ein Datenbank Update bei jedem Deploy auf einem spezifischen host verwenden werden.
Weiters können ebenso Variablen verwendet werden, dies erlaubt zB. Passwörter oder System Informationen zu übergeben.


*Syntax:* `exec [host] [if <condition>]: command`

**6. var**

Dieses Kommando erlaubt es eine host Variable von einem "def" oder "undeploy" File zu setzen, 
diese kann später as Normale Variable (<%VAR:varname%> - siehe [Variables](variables.md)) verwendet werden.
Die Variable kann ebenso mit dem Output eines exec Kommandos benutzt werden. 
Wenn eine gleichnamige Variable existiert wird diese überschrieben.

*Syntax:* `var <varname> = exec [host] [if <condition>]: command`

**7. monitor**

Dieses Kommando erlaubt die Überwachung eines Services. 
Der Service Parameter muss gleichnamig dem "monitor" file im `data/monitors` sein und muss existieren.
Conditionals werden ebenso akzeptiert.

*Syntax:* `monitor [if <condition>]: service`

**8. deploy**

Dieses Kommando erlaubt es Deploys in einem Deploy zu starten und erlaubt sogar die Erstellung eines Meta Deploys mit mehreren Deploys und Conditional Blöcke.
Conditionals werden ebenso akzeptiert.


*Syntax:* `deploy [if <condition>]: another_deploy`

**9. reboot**

Reboot eines System, dieses Kommando erfordert keinen Doppelpunkt und der einzige weitere Erlaube Parameter ist eine Conditional.

Bitte beachte das dieses Kommando am Ende eines Deploys benutzt werden muss um eine Kommunikationsstörung mit dem ASYD Server zu vermeiden.


*Syntax:* `reboot [if <condition>]`
