Instalando ASYD
===============
<br/>

**1. Instalar dependencias**

La mayoría de las dependencias se instalan a través de gems, pero antes necesita ruby, git,
make y algunas librerías estándar para que funcione.

En sistemas basados ​​en Debian:

    apt-get update && apt-get install -y ruby1.9.1-full ruby1.9.1-dev git libxslt-dev libxml2-dev libsqlite3-dev make

En sistemas basados ​​en RedHat:

    yum install -y ruby ruby-devel git libxslt-devel libxml2-devel libsqlite3-devel make

**2. Instalar ASYD desde git**

Instala bundler y clona el repositorio desde git

    gem install bundler
    git clone https://github.com/AsydSolutions/asyd.git

O desde la rama de desarrollo (recomendado mientras se encuentre en estado de desarrollo,
podría ser inestable)

    git clone https://github.com/AsydSolutions/asyd.git -b devel

E instalar ASYD y todas las dependencias

    cd asyd
    bundle install

**3. Iniciar ASYD**

    passenger start

Accede a la nueva instalación de ASYD desde la máquina en si o usando la IP y
el puerto 3000
([http://localhost:3000/](http://localhost:3000/))

**4. Configuración**

Una vez que abra ASYD por primera vez, se le pedirá un usuario, correo electrónico, contraseña y claves ssh, que pueden ser proporcionadas
por el usuario o automáticamente generadas por ASYD.

Cuando se hayan proporcionado todos los datos, ASYD establecerá la nueva instalación y le permitirá usarlo.
