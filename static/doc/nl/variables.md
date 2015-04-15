Variabelen
==========
</br>
ASYD bied een set van globale variabelen aan, met relatie tot de host
 informatie, en bied de mogelijkheid om eigen variabelen te maken
 (zie "[Basis](basics.md) - Hosts en Hostgroepen toevoegen" in de
 documentatie.

Je kan deze variabelen gebruiken in elk configuratie bestand, deploy
 definitie, voorwaarden en "monitor" bestanden voor service monitoring.
 Deze variabelen zullen automatisch vervangen worden met hun waarde
 (tenzij het `noparse` argument of tag wordt anders bepaalt). Alle
 variabelen zijn hoofdletter ongevoelig, wat wil zeggen dat `<%IP%>` en
 `<%ip%>` dezelfde waarde zullen bevatten.

<br/>
Globale variabelen:
-------------------
<br/>

    <%ASYD%> - ASYD server IP
    <%HOSTNAME%> - Doelhost naam
    <%IP%> - Doelhost IP
    <%DIST%> - Doelhost Linux distributie
    <%DIST_VER%> - Doelhost distributie versie
    <%ARCH%> - Doelhost architectuur
    <%PKG_MANAGER%> - Doelhost package manager
    <%MONITOR:service%> - Niet echt een variabele, monitort 'service'

<br/>
Eigen variabelen:
-----------------
<br/>
Je kan ook je eigen variabelen maken in zowel hosts als hostgroepen. Je
 kan ook de waarde van een variabele toegekend aan een hostgroep
 overriden door een variabele met dezelfde naam te definiëren op de
 host.

    <%VAR:varnaam%> - Gebruik de waarde toegekend aan "varnaam"
