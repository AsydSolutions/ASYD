Installing ASYD
===============
<br/>

**1. Install dependencies**

Die meisten Abhängigkeiten werden via gems installiert, aber zur Grundinstallation werden ruby, git, make sowie einige Libraries
benötigt. 

Auf Debian Systemen:

    apt-get update && apt-get install -y ruby1.9.1-full ruby1.9.1-dev git libxslt-dev libxml2-dev libsqlite3-dev make

Auf RedHat basierten Systemen:

    yum install -y ruby ruby-devel git libxslt-devel libxml2-devel libsqlite3-devel make

**2. Installiere ASYD von git**

Installiere Bundler und Klone das git Repository:

    gem install bundler
    git clone https://github.com/AsydSolutions/asyd.git

Oder installiere die Development Version. (Empfohlen da derzeit noch große Änderungen vorgenommen werden)

    git clone https://github.com/AsydSolutions/asyd.git -b devel

Installiere ASYD und die nötigen Abhängigkeiten:

    cd asyd
    bundle install

**3. Starte ASYD**

    passenger start

Greife via Port 3000 und Localhost bzw. der Server IP auf ASYD zu:
([http://localhost:3000/](http://localhost:3000/))

**4. Setup**


Beim ersten öffnen wird der User Account angelegt sowie ein SSH key Importiert bzw. Generiert.
