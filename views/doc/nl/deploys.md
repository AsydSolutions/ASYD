Deploys
=======
<br/>
Een "deploy" is een groep of uitvoerbare acties en configuraties die je
 toelaat om automatisch software te installeren of verwijderen,
 configuratiebestanden te parsen en up te loaden, commando's uit te
 voeren op een doelsysteem of een afzonderlijk (ingesteld) systeem,
 services en systemen monitorren, en in het algemeen je infrastructuur
 op te zetten en het klaar te maken voor productie in een enkele klik

De deploys kunnen terug gevonden worden of ge-upload worden naar de
 "data/depeloys/" map op uw ASYD installatie.

<br/>
Deploy structuur:
-----------------
<br/>

* Een map met de naam van de deploy (bvb `data/deploys/LAMP`. Deze naam
 zal weergegeven worden op de ASYD web interface in het "Deploys"
 gedeelte.
* Een "def" bestand (bvb `data/deploys/LAMP/def`) met de definitie die
 bepaalt wat de deploy zal doen - packages installeren, commando's
 uitvoeren, configuraties uploaden, condities, etc.
* Optioneel, een "def.sudo" bestand (bvb `data/deploys/LAMP/def.sudo`)
 in het geval we het willen uitvoeren als super user in plaats van de
 standaard "def", wanneer we een non-root gebruiken.
* Optioneel, een "undeploy" bestand (bvb `data/deploys/LAMP/undeploy`)
 met de stappen nodig om een Deploy ongedaan te maken (undeploy).
* Optioneel, een "undeploy.sudo" bestand (bvb
 `data/deploys/LAMP/undeploy.sudo`), zijnde het "undeploy" equivalent
 van "def.sudo"
* Een "configs" map met de configuratie bestanden en mappen die
 geupload moeten worden. (bvb
 `data/deploys/LAMP/configs/apache/apache.conf`).

**Opmerking over "def.sudo":** dit definitie bestand zal enkel
 uitgevoerd worden in plaats van het normale "def" bestand wanneer de
 gebruiker die op het remote systeem uitvoert niet "root" is en het
 bestand bestaat. Dit is vooral nuttig op Ubuntu machines, die geen
 root gebruikers gebruiken. For de machines met de root gebruiker wordt
 het standaard "def" bestand uitgevoerd, ongeacht of het "def.sudo"
 bestand bestaat of niet. Als het bestand niet bestaat zal het standaard
 "def" bestand uitgevoerd worden, ook voor niet-root gebruikers.
 Hetzelfde geld voor "undeploy.sudo"

<br/>
Het "def" bestand:
------------------
<br/>
Zowel het "def" als het "def.sudo" bestand, gebruikt voor het
 definieren van deploys, accepteren volgende commando's en parameters.
 Dezelfde regels zijn van toepassing op de "undeploy" en
 "undeploy.sudo" bestanden.

*Let top de dubbelpunt - : - na de condities en voor de argumenten,
 aangezien deze nodig zijn om de deploy te doen werken.*

**0. commentaar**

Iedere lijn die start met een hashtag (#) wordt geinterpreteerd als
 commentaar en zal niet uitgevoerd worden. Er is een speciaal soort
 commentaar, de "alert", die een waarschuwing geeft voor het uitvoeren
 van een deploy. Dit is nuttig wanneer je deploy aangepaste variabelen
 nodig heeft of wanneer je wil dat de gebruiker zaken controleert voor
 het uitvoeren van een deploy. Belangerijk om weten is dat deze alerts
 enkel werken op "def" bestanden, en niet op "def.sudo" bestanden.
De alerts worden toegevoegd door de lijn te starten met `# alert:`

*Syntax:* `# Normale commentaar`

*Syntax:* `# Alert: Bericht dat getoond moet worden voor de deploy
 uitgevoerd wordt`

**1. installatie**

Het installatie commando kan gebruikt worden om een lijst van packages
 (gesplitst door een spatie) te definieren die moeten geinstalleerd
 worden op het doelsysteem> Intern zal ASYD kijken wat soort systeem
 het de packages op zal installeren, en zal de bijpassende package
 manager gebruiken. Optioneel kan je conditionelen definieren - Lees
 het onderdeel [Conditionelen](conditionals.md) voor meer informatie.
Op Solaris systemen accepteert het ook een extra argument om de package
 manager te specifieren. Lees [Solaris](solaris.md) voor een meer
 gedetailleerd overzicht. 

*Syntax:* `install [if <voorwaarde>]: package_a package_b package_c`

**2. uninstall**

