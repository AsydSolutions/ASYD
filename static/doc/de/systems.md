Unterstützte Systeme
=================
<br/>

ASYD sollte in der Theorie mit jedem OS/Betriebssystem mit SSH Zugang funktionieren, es gibt allerdings
System Spezifische Funktionen wie die install und monitoring Kommandos die nur auf Offiziell Unterstützden OS/Betriebssystemen funktionieren.


*Notiz für Entwickler: Wenn ASYD mit dem anderen System verwendet werden soll kann die Zeile
`raise #OS not supported yet` on the initialize() function in models/host.rb kommentiert werden. Wir übernehmen keine Verantwortung/Haftung
für Problem die dies Erzeugen kann.

<br/>
Unterstützte hosts:
------------------

Derzeit unterstützte Systeme:

 * Debian
 * Ubuntu
 * RedHat
 * Fedora
 * CentOS
 * Arch Linux
 * OpenSUSE
 * Solaris/OpenIndiana
 * OpenBSD

*Notiz: Jedes Derivat dieser Systeme (zB. CloudLinux) sollte ebenfalls funktionieren.
Wenn Bugs oder Probleme auftreten kontaktiere uns bitte unter info@asyd-solutions.com*

<br/>
Supported Servers:
------------------

Du kannst ASYD selbst auf jedem Linux/UNIX/POSIX System mit Ruby Unterstützung Installieren (Ausnahme: Mac OSX, durch einen Fork Bug)
