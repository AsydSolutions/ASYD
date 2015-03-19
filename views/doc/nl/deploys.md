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
 uitvoeren, configuraties uploaden, voorwaarden, etc.
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

*Let top de dubbelpunt - : - na de voorwaarden en voor de argumenten,
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

Het uninstall commando werkt net als het install commando, maar voor
 het verwijderen van packages. Het accepteert ook voorwaarden en
 package manager, in het geval van Solaris

*Syntax:* `uninstall [if <voorwaarde>]: package_a package_b package_c`

**3. config file**

Dit commando laat to om configuraties die opgeslaan zijn in de "configs"
 map (eerste parameter) te uploaden naar het pad van de doel host
 (tweede parameter). De naam van het locale bestand moet dezelfde zijn
 als die in de "configs" map van de deploy, maar je kan kan gelijk
 welke naam gebruiken op het target, aangezien de naam zal gewijzigd
 worden tijdens de upload. Het accepteert ook voorwaarden en een
 "noparse" argument in het geval je het configuratie bestand niet wil
 laten parsen voor upload, maar het wil uploaden zoals het is.
Lees ook de [Configurations](configurations.md) documentatie.

*Syntax:* `[noparse] config bestand [if <voorwaarde>]: bestand.conf,
 /doel/pad/bestand.conf

**4. config dir**`

Werkt hetzelfde als het "config file" commando, maar inspecteert
 recursief alle bestanden en submappen in de map, en verwerkt elk
 configuratiebestand. Zoals bij "config file" aanvaart het ook extra
 voorwaarden en de "noparse" parameter (zie "config file")

*Syntax:* `[noparse] config dir [if <voorwaarde>]: config map, doel/map`

**5. exec**

Dit commando voert een (bash/sh) commando uit dat door de gebruiker
 gespecifieerd werd, en is dus het meest veelzijdige commando in ASYD.
Het accepteerd optitionele voorwaarden en ook een host parameter, waarmee
 je specifieerd op welke host je het commando wilt uitvoeren, in plaats
 van de deploy (bvb. wanneer je een database wilt updaten of een actie
 op een host wilt uitvoeren elke keer een nieuw systeem gedeployed
 wordt). Het exec commando aanvaard ook variabeles voor het commando,
 dus kan je paswoorden, variabele parameters, systeem informatie, etc
 als parameters meegeven voor elk commando.

*Syntax:* `exec [host] [if <voorwaarde>]: commando`

**6. var**

Dit commando laat toe om een host variabele van een "def" of "undeploy"
 bestand te maken, dat later aangeroepen kan worden als een normale
 variabele (<%VAR:varnaam%> - zie [Variabelen](variables.md)). De
 varirabele kan gezet worden met de output van het "exec" commando -
 Verifieer dat het commando een output produceert. Als een variabele met
 dezelfde naam bestaat, zal deze overschreven worden met de nieuwe
 waarde.

*Syntax:* `var <varnaam> = exec [host] [if <voorwaarde>]: commando`

**7. monitor**

Dit commando laat u toe een service te monitorren. De service parameter 
 moet dezelfde naam hebben als het monitor bestand in de `data/monitors`
 map, dat moet bestaan. Je kan ook verschillende services specifieren,
 gescheiden meet een spatie. Het accepteert ook optionele voorwaarden.

*Syntax:* `monitor [if <voorwaarde>]: service`

**8. deploy**

Met dit commando kan je ook andere deploys van een deploy launchen, wat
 zelf toelaat om meta-deploys te creeeren die voorwaarden voor deploys
 bevatten. De genoemde deploy moet bestaan. Dit commando accepteert ook
 optionele voorwaarden.

*Syntax:* `deploy [if <voorwaarde>]: another_deploy`

**9. reboot**

Dit commando herstart het systeem. De dubbele punt - : -  is niet
 vereist bij dit commando, en de enige parameter die toegelaten is is
 een voorwaarde. **Opgelet** Dit commando moet altijd gebruikt worden
 op het einde van een deploy, anders zal de ASYD server communicatie
 met de doelhost verliezen, en zullen de volgende commando's niet
 uitgevoerd worden.

*Syntax:* `reboot [if <voorwaarde>]`
