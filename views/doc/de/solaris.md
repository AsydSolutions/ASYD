Solaris
=======
<br/>
ASYD bietet Solaris Unterstützung (Version 8 und neuer) sowie Openindiana Unterstützung.
Diese Systeme haben einige unten beschriebene Eigenheiten.

<br/>
Paketmanager
----------------
<br/>
Da Solaris Versionsbedingt mehrere/unterschiedliche Paketmanager anbietet prüft ASYD Intern einige Dinge.

ASYD unterstützt derzeit installationen via:

**1. pkgadd**

Der älteste Paketmanager, verfügbar auf jedem Solaris/Openindiana System.
Auf Solaris 10 und höher unterstützt pkgadd URLs, somit können Pakete direkt mit dem ´install` Kommando
oder der Schnellen Installation angegeben werden. 

Für Solaris 9 und älter muss das Paket manuell heruntergeladen und der Pfad spezifiziert werden.

Die Installationskommandos für diesen Paketmanager wird so ausgeführt:
`pkgadd -a /etc/admin -d <packagename> all`
Das `/etc/admin` File wird beim Monitoring Setup übertragen um Eingaben mit pkgadd zu vermeiden.

**2. pkg**

Dieser Paketmanager ist auf Solaris 11 und Openindiana verfügbar, er funktioniert ähnlich den Linux 
Paketmanagern und bezieht seine Software aus einer Repository Quelle.


**3. pkgutil**

Nicht nativ in Solaris sondern von einem Drittproduzenten [OpenCSW](http://www.opencsw.org).
Pkgutil funktioniert in jeder Solaris/Openindiana Umgebung und bringt weit verwendete Software mit.
ASYD Installiert OpenCSW auf Solaris/Openindiana Systemen während des Monitoring Setups, der Paketmanager kann
via Modifikation des "monit" deploys deaktiviert werden.

<br/>
Installing Software
-------------------
<br/>
Standardmässig wird das "install" Kommando ohne Parameter und Schnelle Installation pkg verwenden.
Sofern pkg nicht verfügbar ist wird pkgadd verwendet.

Dies kann in im "install" Kommando modifiziert werden:

  * pkgadd: `install pkgadd [if condition]: package`
  * pkg: `install pkg [if condition]: package`
  * pkgutil: `install pkgutil [if condition]: package`

Gleiches gilt für das `uninstall` Kommando.
