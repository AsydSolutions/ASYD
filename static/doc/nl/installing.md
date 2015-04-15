Installatie van ASYD
====================
<br/>

**1. Installeer dependencies**

De meeste dependencies worden geïnstalleerd via gems, maar ruby, git,
 make en enkele standaard libraries zijn vereist.

Op Debian-based systemen (als root):

    apt-get update && apt-get install -y ruby1.9.1-full ruby1.9.1-dev git libxslt-dev libxml2-dev libsqlite3-dev make

Op RedHat-based systemen:

    yum install -y ruby ruby-devel git libxslt-devel libxml2-devel libsqlite3-devel make

**2. Installeer ASYD met git**

Installeer bundler en clone de git repository

    gem install bundler
    git clone https://github.com/AsydSolutions/asyd.git

Of neem de ontwikkelings tak (aan te raden wanneer het project in zware
 ontwikkeling is, hoewel het onstabiel kan zijn)

    git clone https://github.com/AsydSolutions/asyd.git -b devel

Installeer ASYD en  alle dependencies

    cd asyd
    bundle install

**3. Start ASYD**

    passenger start

Benarder je pas geïnstalleerde ASYD systeem vanop de machine zelf, of
 via het IP en op poort 3000
([http://localhost:3000/](http://localhost:3000))

**4. Set-up**

Wanneer je ASYD voor de eerste maal opstart zal het voor een gebruiker,
 email, paswoord en ssh keys vragen. Deze kunnen door de gebruiker
 meegegeven worden, of automatisch gegenereerd worden door ASYD.

Wanneer alle data meegegeven is, zal ASYD de nieuwe installatie
 opzetten, en kan je het gebruiken.
