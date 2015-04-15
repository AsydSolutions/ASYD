Voorwaarden
===========
<br/>
Voorwaarden worden gebruikt om regels voor het uitvoeren van commando's
 te definiëren, of te bepalen welke configuratie er moet gebruikt worden
 op een host of hostgroep.

Aanvaarde voorwaarden zijn `==` (gelijk), `!=` (niet gelijk), `>=`
 (groter of gelijk) en `<=` (kleiner of gelijk). De `>=` en `<=`
 operatoren kunnen enkel voor cijfers gebruikt worden. de `==` en `!=`
 operatoren kunnen zowel voor Strings (tekst vergelijking) als nummers
 gebruikt worden.

Enkele condities (zoveel als je wil) kunnen samengevoegd worden met
 `and` en `or`. Deze zullen volgens sequentiële en logische volgorde
 geïnterpreteerd worden (bvb voor `voorwaarde1 or voorwaarde2`, als de
 eerste voorwaarde voldoet, zal de tweede niet geëvalueerd worden).

<br/>
Gebruik:
--------
<br/>
**1. Voorwaarde blokken op "def" bestanden**

Voorwaarden kunnen gebruikt worden om blokken in een "def" bestand te
 definiëren, die enkel uitgevoerd worden wanneer de voorwaarde voldoet.
Zowel de opening tag `if <voorwaarde>` en de eind tag `endif` moeten op
 een enkele lijn geschreven worden, zonder extra karakters, buiten de
 aanvaarde parameters. Tussen deze kun je elk commando gebruiken dat
 uitgevoerd moet worden wanneer de voorwaarde voldoet.

*Let op: Je kan geen voorwaarde blokken in voorwaarde blokken gebruiken,
 maar enkel een per een. Je kan wel single-line voorwaarden gebruiken,
 zoals omschreven in het volgende deel.

*Syntax:*

    if <%var%> == waarde [or|and voorwaarde2] [or|and ...]
    [...]
    endif

*Voorbeeld:*

    if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_VER%> >= 5
    install: package
    exec: commando
    endif

**2. Single-line commando's in "def" bestanden**

Voorwaarden kunnen gebruikt worden voor single-line commando's binnen
 een "def" bestand. De standaard syntax wordt gebruikt, en je kan ook
 voorwaarden voor concrete commando's gebruiken, zelf binnen voorwaarde
 blokken (zie vorige)

*Syntax:*

    exec if <%var%> == waarde [or|and voorwaarde2] [or|and ...]: commando

*Voorbeeld:*

    install if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_VER%> >= 5: package

**3. Voorwaarde blokken in configuratie bestanden**

Voorwaarden kunnen ook gebruikt worden binnen configuratiebestanden (zie
 [Configuraties](configurations.md) voor de documentatie) voor het
 bepalen van delen van de configuratie die enkel voor bepaalde target
 systemen geüpload mogen worden wanneer de voorwaarde geld. Het gebruik
 is dezelfde als bij voorwaarde blokken bij "def" bestanden (zie vorige)
 maar gedefinieerd met de tags `<%if voorwaarde%>` `<%endif%>`.

*Opgelet: Je kan geen voorwaarde blokken binnen voorwaarde blokken
 gebruiken, enkel een per een.*

*Syntax:*

    <%if <%var%> == waarde [or|and voorwaarde2] [or|and ...]%>
    [...]
    <%endif%>

*Voorbeeld:*

    <%if <%DIST%> == debian and <%DIST_VER%> == 6%>
    configuratie die enkel geld voor Debian 6
    <%endif%>
    <%if <%DIST%> == debian and <%DIST_VER%> >= 7%>
    configuratie die enkel geld voor Debian 7 of nieuwer
    <%endif%>
    configuratie voor alle systemen
