Básicos
=======
<br/>

Casi todo en ASYD funciona usando la interfaz web, esto te permite gestionar
todos los sistemas, hostgroups, usuarios, equipos, monitorizar tus servidores y gestionar y lanzar
deploys.

La monitorización está gestionada por [monit](http://mmonit.com/monit/) en los host remotos,
que se comunica con el servidor ASYD.

<br/>
Añadir Hosts y Hostgroups:
----------------------------
<br/>
Una vez que te has identificado en ASYD, ve a la sección "Server overview", allí veras los host y hostgroups
existentes, los hosts que pertenecen a un hostgroup y el estado de sus servidores.

Desde esta pantalla puedes abrir el detalle de los hosts o hostgroups, realizar un reinicio de un sistema remoto,
eliminar hosts y hostgroups existentes o añadir nuevos.

Para añadir un nuevo servidor, click en el botón "Add host" y aparecerá un diálogo,
donde debes introducir un hostname único, la IP del servidor, el usuario para este host,
el puerto ssh si has configurado un puerto no estándar y la contraseña para ese usuario.
ASYD añadirá la llave ssh de la aplicación en el archivo ~/.ssh/authorized_keys del host remoto
para los futuros accesos, con lo que la contraseña provista no se guardará. Alertnativamente,
puedes dejar el campo de la contraseña vacío, en cuyo caso ASYD intentará autentificar el nuevo
host usando la clave SSH creada o provista durante el setup.

Nota: si estás usando un usuario distinto a root (como en el caso de ubuntu o similar),
necesitas asegurarte de que ese usuario tiene privilegios de administrador, el comando "sudo" está instalado,
y el usuario no necesita proveer una contraseña para sudo, ya que el sistema de deploys de ASYD
funciona en modo no-interactivo. Esto se puede conseguir añadiendo la linea `%sudo   ALL=(ALL:ALL) NOPASSWD:ALL`
al archivo `/etc/sudoers`.

Después de que el nuevo host sea añadido, se iniciará el deploy de monitoring en segundo plano, en este
momento el servidor aparecerá como "no monitorizado". Cuando la configuración de la monitorización se haya completado,
abriendo el detalle del host te mostrará toda la información del sistema, el estado reportado por
monit, y también podrás crear variables personalizadas para el host.

Para añadir un nuevo hostgroup, click en el botón "Add group" y un diálogo aparecerá, donde
tienes que introducir un nombre único para el nuevo hostgroup.

Tras ser creado el nuevo hostgroup, puedes abrir el detalle del grupo y añadir servidores,
o personalizar variables. Un mismo host puede ser incluido en distintos grupos.

<br/>
Instalación Rápida:
--------------
<br/>
ASYD ofrece la posibilidad de instalar paquetes individuales en un host o hostgroup. Para
hacer esto, accede a la sección de "Deploys" y usa el diálogo llamado "Quick Install". Puedes
también instalar múltiples paquetes separados por espacios (ej. htop nano vim).

La rutina de instalación está manejada por ASYD, que comprobará el tipo de sistema y el
gestor de paquetes a usar, así que esta opción puede ser usada para instalar paquete en cualquier tipo de
sistema soportado. Por favor ten presente que los paquetes no siempre son llamados de la misma forma en todos los sistemas,
así que a menos que estes seguro de que el nombre del paquete es el mismo en las distintas distribuciones, deberías
no usar esta función en grupos que contengan diferentes tipos de sistemas.

Por favor lee también la sección [Solaris](solaris.md)  para información más detallada sobre como funciona
en sistemas Solaris.

<br/>
Estructura de datos de ASYD:
-------------------
<br/>

  * `asyd.rb - config.ru`: archivos de base para que ASYD funcione, `asyd.rb` contiene las rutinas básicas de
  inicialización y `config.ru` permite a Phusion Passenger iniciar y gestionar
  la aplicación.
  * `installer/`: contiene los archivos de monitorización predefinidos y el deploy de monitorización para lanzar
  monit en los host añadidos. Esta carpeta queda borrada una vez la configuración está completa.
  * `models/`: contiene todo el núcleo de ASYD, todas las funciones para su puesta en marcha.
  * `routes/`: contiene las rutas y acciones a realizar en función de la petición.
  * `views/`: contiene todos los views (páginas web) que se mostrarán en la interfaz web.
  * `static/lib/`: contiene todo el javascript, css y las imágenes.
  * `data/`: almacena todos los datos de ASYD.
    * `data/db/`: varios archivos SQLite DB para almacenar hosts, hostgroups, usuarios, equipos, tareas, notificaciones,
    las notificaciones de monitoreo y el estado del sistema.
    * `data/deploys/`: donde los deploys son almacenados (Información detallada en la sección
    [Deploys](deploys.md) de la documentación).
    * `data/monitors/`: archivos de definición de monit para el seguimiento de los servicios.
