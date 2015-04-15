Solaris
=======
<br/>
ASYD soporta tanto Solaris (desde la versión 8 en adelante) y OpenIndiana, pero estos sistemas tienen
algunas particularidades, descritas a continuación.

<br/>
Gestores de Paquetes
--------------------
<br/>
Como Solaris tiene diferentes gestores de paquetes o formas de instalar paquetes dependiendo de
la versión, ASYD realiza algunas comprobaciones internas en este sentido.

ASYD actualmente soporta la instalación de paquetes usando:

**1. pkgadd**

El gestor de paquetes más antiguo para Solaris, y disponible en cualquier sistema Solaris/OpenIndiana.
En Solaris 10 y superiores, pkgadd soporta URLs de forma que puedes instalar paquetes directamente desde
internet solo especificando la URL en el comando "install" en el archivo def o usando el
"Quick Istall". Para Solaris 9 y anteriores, necesitas descargar primero el paquete a algún directorio
e instalarlo especificando la ruta completa.

El comando de instalación para este gestor de paquetes en ASYD se realiza internamente de la siguiente manera
`pkgadd -a /etc/admin -d <packagename> all`, instalando todo el contenido en el paquete.
El archivo `/etc/admin` es cargado durante la instalación de la monitorización para evitar diálogos cuando usas pkgadd.

**2. pkg**

Este gestor de paquetes está disponible en Solaris 11 y OpenIndiana, funciona de forma similar
a los gestores de paquetes en Linux, descargando paquetes desde un repositorio de software.
No tiene requisitos especiales.

**3. pkgutil**

No es nativo de Solaris sino que es un repositorio externo, [OpenCSW](http://www.opencsw.org).
Funciona en cualquier versión de Solaris/OpenIndiana y ofrece muchas utilidades comunes y
software. ASYD instala OpenCSW en el sistema Solaris/OpenIndiana cuando deployea
la monitorización, en cualquier caso puedes deshabilitarlo eliminando o comentando la línea
en los archivos def y def.sudo para el deploy de "monit".

Funciona como cualquier otro gestor de paquetes, no requiere ninguna opción especial.

<br/>
Instalando Software
-------------------
<br/>
Por defecto el comando `install` sin parámetros, o "Quick Install", usará `pkg`
como gestor de paquetes, o si este no está disponible, usará `pkgadd`.

Puedes eliminar el comportamiento por defecto en el comando `install` en los archivos "def" añadiendo uno de
los gestores de paquetes:

  * pkgadd: `install pkgadd [if condition]: package`
  * pkg: `install pkg [if condition]: package`
  * pkgutil: `install pkgutil [if condition]: package`

Lo mismo se aplica al comando `uninstall`.
