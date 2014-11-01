Sistemas Soportados
===================
<br/>

Aunque en teoría ASYD funciona con cualquier sistema que soporte SSH, hay algunas
funciones dependientes del sistema, como el comando de instalación o el proceso de instalación
del monitoring, que solo funcionarán en los sistemas oficialmente soportados.

*Nota para desarrolladores: si quiere usar ASYD con cualquier otro sistema igualmente, puede
comentar la línea `raise #OS not supported yet` en la función initialize() en models/host.rb.
No nos hacemos responsables de comportamientos extraños que puedan suceder.*

<br/>
Clientes Soportados:
--------------------

Actualmente puedes añadir sistemas basados en:

 * Debian
 * Ubuntu
 * RedHat
 * Fedora
 * CentOS
 * Arch Linux
 * OpenSUSE
 * Solaris/OpenIndiana
 * OpenBSD

*Nota: cualquier derivación o distribución basada en las anteriormente mencionadas debería
funcionar también. Si encuentras algún problema con cualquiera de los sistemas soportados o
con sistemas basados en estos, por favor contactanos en info@asyd-solutions.com*

<br/>
Servidores Soportados:
----------------------

Puedes instalar el servidor de ASYD en cualquier sistema Linux/UNIX/POSIX con soporte para Ruby
excepto MacOS, debido a un bug conocido en el proceso del forking.
