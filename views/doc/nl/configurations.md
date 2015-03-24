Configuraties
=============
<br/>
De configuraties zijn een belangrijk onderdeel van ASYD. Je kan elk
 bestand of map in de "configs" op een deploy gebruiken, en ze uploaden
 met het "def" bestand van een deploy.

Elk configuratiebestand zal geparset worden, op zoek naar variabelen en
 voorwaarden, wat een hoop flexibiliteit geeft tijdens het deployen en
 configureren van systemen. Verder zullen de configuratiebestanden in
 configuratie mappen en submappen recursief geparset en geüpload worden.

Je kan dit gedrag globaal negeren door de "noparse" parameter te
 gebruiken op het def bestand wanneer je een configuratie bestand of map
 upload (zie [Deploys](deploys.md) in de documentatie). Je kan ook
 bepaalde blokken die niet geparset mogen worden in de configuratie
 bestanden plaatsen met de `<%noparse%>` `<%/noparse%>` tags.

Voorwaarden kunnen ook in configuratie bestanden gebruikt worden voor
 delen van de configuratie die enkel moeten toegevoegd worden wanneer de
 voorwaarde geld voor de host. Deze voorwaarde blokken worden
 gedefinieerd binnen de `<%if voorwaarde%>` `<%endif%>` tags (vervang
 "voorwaarde" met de effectieve voorwaarde). Voorwaarden binnen de
 noparse tags worden ook niet geëvalueerd.

**Belangrijk:** Hou er rekening mee dat elke deel van "noparse" tags op
 dezelfde lijn moet worden geschreven opdat deze zouden werken. bvb:

    <%noparse%>
    code die niet geparset moet worden
    <%/noparse%>
    rest van het bestand

*Lees ook het [Variabelen](variables.md) gedeelte van de documentatie
 voor een lijst van de beschikbare variabelen, en het [Voorwaarden]
(conditionals.md) gedeelte voor meer informatie over het gebruik er van.*
