Ondersteunde Systemen
=====================
<br/>

Hoewel ASYD in theorie werkt op elk systeem dat SSH ondersteunt, zijn er
 enkele systeem-specifieke zaken, zoals het install commando, of de
 monitor set-up, die enkel werken op officieel ondersteunde systemen.

*Voor ontwikkelaars: moest je ASYD toch op een ander systeem wilt
 gebruiken, kan je de lijn `raise #OS not supported yet` uit commenteren
 in models/host.rb. Wij zijn niet verantwoordelijk voor mogelijke
 vreemde bijwerkingen die hierdoor kunnen gebeuren.*

<br/>
Ondersteunde Clients:
---------------------

Je kan momenteel onderstaande systemen toevoegen gebaseerd op:

 * Debian
 * Ubuntu
 * RedHat
 * Fedora
 * CentOS
 * Arch Linux
 * OpenSUSE
 * Solaris/OpenIndiana
 * OpenBSD

*Let op: elke afsplitsing of distributie gebaseerd op deze lijst zou
 normaal moeten werken. Moest je een uitzondering tegen komen, gelieve
 ons te contacteren op info@asyd-solutions.com*

<br/>
Ondersteunde Servers:
---------------------

Je kan ASYD zelf op elk Linux/UNIX/POSIX systeem met ruby installeren,
 behalve MacOS. Dit door een gekende bug in het forking proces.
