Basis
=====
<br/>

Vrijwel alles in ASYD werkt via de web interface.
Het laat je toe om alle systemen, host-groepen, gebruikers, teams,
 te beheren, alsook het monitorren van je servers en het uitvoeren
 van deploys.

Het monitorren van remote hosts wordt beheerd door
 [monit](http://mmonit.com/monit/), wat communiceert met de ASYD server.
 
<br/>
Hosts en Host-groepen toevoegen:
--------------------------------
<br/>
Eenmaal je ingelogd bent in ASYD, ga naar het "Server overview"
 onderdeel. Daar zul je de bestaande hosts en host-groepen zien, alsook
 de systeem status voor je servers.

Op het overzicht kan je de details van de hosts en host-groepen
 bekijken, systemen heropstarten, hosts van host-groepen verwijderen
 of toevoegen.

Voor het toevoegen van servers, klik op de "Add host" knop en een
 invoerveld zal verschijnen. Daar moet je een unieke hostnaam voorzien,
 vergezeld van het server IP, de gebruiker voor de host, de SSH poort
 (indien je een niet-standaard ssh poort gebruikt), en het paswoord
 voor die gebruker.
ASYD zal dan de ASYD ssh sleutel aan het ~/.ssh/authorized_keys bestand
 van de remote host toevoegen. Dit zal gebruikt worden bij toekomstige
 connectites, en op deze manier wordt het paswoord niet opgeslagen op
 het systeem. Anderzijds kan je het paswoord veld leeg laten. Dan zal
 ASYD proberen om the authenticeren met de hosts, door gebruik te maken
 van de gecreeerde SSH sleutel, of de sleutel die meegegeven werd bij
 de setup.

Neem in acht dat wanneer je een niet-root gebruiker wil toevoegen
 (zoals het geval bij Ubuntu of gelijkaardige systemen), je zeker moet
 zijn dat de gebruiker admin previleges heeft, het sudo commando
 geinstalleerd is, en de gebruiker niet om zijn paswoord gevraagd wordt
 bij het uitvoeren van het sudo commando, aangezien ASYD deploying
 system niet interactief is.
Dit kan je doen door `%sudo   ALL=(ALL:ALL) NOPASSWD:ALL` toe te voegen
 aan het `/etc/sudoers` bestand.

