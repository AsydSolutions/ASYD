Solaris
=======
<br/>
ASYD ondersteunt zowel Solaris (versie 8 en hoger) en OpenIndiana, maar
 deze systemen hebben enkele specifieke zaken, zoals hieronder
 beschreven.

<br/>
Package Managers
================
<br/>
Doordat Solaris verschillende package managers heeft, en de manier van
 het installeren van packages anders is, afhankelijk van de versie, doet
 ASYD enkele checks met betrekking tot dit.

ASYD ondersteunt momenteel volgende package managers:

**1. pkgadd**

De oudste package manager voor Solaris, en beschikbaar op elk Solaris/
 OpenIndiana platform. Op Solaris 10 en hoger Ondersteunt pkgadd URLs,
 waardoor je packages direct vanop internet kunt installeren door de URL
 mee te geven aan het `install` commando op een def bestand, of door
 gebruik te maken van de "Quick Install". Voor Solaris 9 en lager moet
 je eerst de package lokaal downloaden en het installeren, gebruik
 makende van het volledige pad.

Het installatie commando voor deze package manager op ASYD voert een
 `pkgadd -a /etc/admin -d <package naam> all` uit, waardoor alle inhoud
 uit de package geïnstalleerd wordt. Het `/etc/admin` bestand wordt
 geüpload tijdens de monitoring set-up om prompts te vermijden wanneer
 pkgadd gebruikt wordt.

**2. pkg**

Deze package manager is beschikbaar op Solaris 11 en OpenIndiana. Het
 werkt net zoals package managers op Linux, door packages te downloaden
 van software repositories, en heeft geen speciale vereisten.

**3. pkgutil**

Niet standaard op Solaris, maar uit een third party repository [OpenCSW]
 (http://www.opencsw.org). Het werkt op elke versie van Solaris/
 OpenIndiana en brengt vele tools en software. ASYD installeert OpenCSW
 op Solaris/OpenIndiana systemen tijdens het deployen van de monitor,
 maar deze optie kan uitgeschakeld worden door deze lijn uit het 
 def.sudo bestand van de "monit" deploy te halen.

Werkt op dezelfde manier als andere package managers, en heeft dus geen
 speciale opties nodig.

<br/>
Installatie Software
--------------------
<br/>
Standaard zullen zowel het `install` commando zonder parameters, of de
 "Quick Install" `pkg` als package manager gebruiken. Wanneer die niet
 gevonden kan worden zal `pkgadd` gebruikt worden.

Je kan het gedrag van `install` overriden door package managers mee te
 geven als parameter:

  * pkgadd: `install pkgadd [if voorwaarde]: package`
  * pkg: `install pkg [if voorwaarde]: package`
  * pkgutil: `install pkgutil [if voorwaarde]: package`

Hetzelfde geld voor het `uninstall` commando.
