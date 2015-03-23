Basis
=====
<br/>

Vrijwel alles in ASYD werkt via de web interface.
Het laat je toe om alle systemen, host-groepen, gebruikers, teams,
 te beheren, alsook het monitoren van je servers en het uitvoeren
 van deploys.

Het monitoren van remote hosts wordt beheerd door
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
 voor die gebruiker.
ASYD zal dan de ASYD ssh sleutel aan het ~/.ssh/authorized_keys bestand
 van de remote host toevoegen. Dit zal gebruikt worden bij toekomstige
 connecties, en op deze manier wordt het paswoord niet opgeslagen op
 het systeem. Anderzijds kan je het paswoord veld leeg laten. Dan zal
 ASYD proberen om te authenticeren met de hosts, door gebruik te maken
 van de gecreëerde SSH sleutel, of de sleutel die meegegeven werd bij
 de set-up.

Neem in acht dat wanneer je een niet-root gebruiker wil toevoegen
 (zoals het geval bij Ubuntu of gelijkaardige systemen), je zeker moet
 zijn dat de gebruiker admin privileges heeft, het sudo commando
 geïnstalleerd is, en de gebruiker niet om zijn paswoord gevraagd wordt
 bij het uitvoeren van het sudo commando, aangezien ASYD deploying
 systeem niet interactief is.
Dit kan je doen door `%sudo   ALL=(ALL:ALL) NOPASSWD:ALL` toe te voegen
 aan het `/etc/sudoers` bestand.

Nadat de nieuwe host toegevoegd is, zal het in de achtergrond de 
 monitoring deploy starten. Op dit moment zal de server als "Not
 monitored" aangeduid staan. Wanneer het monitoring set-up gedaan is,
 zal de host informatie alle systeem informatie en de monit status
 tonen. Je hebt ook de mogelijkheid om eigen variabelen aan te maken.

Om een nieuwe host-groep aan te maken, klik op "Add Group" knop, en een
 invoervak zal verschijnen. Daar kan je een unieke naam voor de nieuwe
 hostgroep kiezen.

Nadat de hostgroep gecreëerd is, kan je het detailoverzicht van de
 groep openen, en servers of variabelen toevoegen. Een enkele host kan
 toegevoegd worden aan meerdere groepen.

<br/>
Snelle installatie:
------------------- 
<br/>

ASYD geeft de mogelijkheid om aparte packages te installeren op hosts
 of hostgroepen. Om dit te doen, ga naar het "Deploy" gedeelte en
 gebruik de "Quick install" dialoog. Je kan ook meerdere packages
 installeren, door ze te scheiden met een spatie (bvb htop nano vim).

De installatie routine wordt beheert door ASYD, die zal kijken wat voor
 soort systeem het is, en welke package manager te gebruiken. Op deze
 manier kan je packages op verschillende types systemen installeren.
 Hou er rekening mee dat packages niet altijd dezelfde naam hebben op
 alle systemen, dus als je niet zeker bent dat deze packages dezelfde
 naam hebben, gebruik je beter geen verschillende systemen in een
 host-groep.

Lees ook de [Solaris](solaris.md) documentatie voor meer gedetailleerde
 informatie over hoe de "Quick install" werkt op Solaris systemen.

<br/>
ASYD data structuur:
--------------------
<br/>

  * `asyd.rb - config.ru`: basis bestanden voor ASYD. `asyd.rb` bevat
 de basis instelling routines en `config.ru` laat Phusion Passenger
 toe om de applicatie te starten en te beheren.
  * `installer/``: bevat de monitor bestanden en de monitoring deploy
 voor het starten van monit op de toegevoegde hosts. Deze map wordt
 verwijderd wanneer de installatie voltooid is.
  * `modules/`: bevat alle ASYD basis bestanden en alle functies om het
 te doen werken.
  * `routes/`: bevat alle routes en acties die moeten uitgevoerd worden
 afhankelijk van de aanvraag.
  * `views/`: bevat alle 'views' (web pagina's) die getoond moeten
 worden bij een aanvraag.
  * `static/lib`: bevat alle javascript, css en foto's voor de views
  * `data/`: bewaart de ASYD data
    * `data/db/`: enkele SQLite  database files om de hosts te
 sorteren, host-groepen, gebruikers, teams, taken, notificaties,
 monitoring notificaties en systeem statussen op te slaan.
    * `data/deploys/`: waar de deploys worden bijgehouden
 (gedetailleerde informatie op [Deploys](deploys.md).
    * `data/monitors/`: monit definitie bestanden voor de monitoring
 service.
