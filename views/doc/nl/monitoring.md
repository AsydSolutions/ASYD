Monitoring
==========
<br/>
Het monitoren van servers en services in ASYD wordt afgehandeld door
 [monit](http://mmonit.com/monit). De ASYD server kijkt naar de lokale
 monit installatie op de remote host voor veranderingen aan de status
 van de server zelf, of services die gemonitord worden.

<br/>
Set-up
------
<br/>
Het monitoren wordt automatisch opgezet op elke host die toegevoegd
 wordt aan ASYD, en gebruik maakt van een "deploy" die **monit**
 installeert en configureert op elk ondersteund systeem.

Deze "deploy" kan gevonden worden onder `data/deploys/monit`, nadat de
 set-up gedaan is. Je deze deploy naar wens aanpassen. Lees het gedeelte
 [Deploys](deploys.md) in de documentatie.

<br/>
Monitors
--------
<br/>
Monitors zijn standaard monit configuratie bestanden die gedefinieerd
 zijn voor een enkele service.

Deze bestanden worden bijgehouden onder `data/monitors/` en aanvaarden
 voorwaarden en variabelen, zoals alle andere configuratie bestanden (
 zie [Configuratie](configurations.md) in de documentatie),wat toe laat
 om een enkel monitor bestand te schrijven voor elke soort host.

De bestandsnaam van het monitor bestand moet dezelfde naam hebben als de
 service die gemonitord wordt (bvb om nginx te monitoren moet het
 monitor bestand `data/monitors/ngginx` bestaan).

Je kan services monitoren

1. Met het `monitor` commando op een "def" bestand.
2. Door de <%MONITOR:service%> mee te geven in een configuratie bestand,
 waar service de naam van de service is, zoals genoemd in het monitor
 bestand.
