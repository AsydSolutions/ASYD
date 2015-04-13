Deploys
=======
<br/>
Un “deploy" es un grupo de definiciones y configuraciones ejecutables que permite
automáticamente instalar o desinstalar software, cargar y analizar sintácticamente configuraciones,
ejecutar comandos en el sistema de destino o de un tercer sistema (definido), monitorear servicios y, en general,
configurar tu infraestructura y dejarlo listo para la producción con un solo click.

Los deploys se pueden encontrar o cargar en el directorio "data/deploys/" en tu instalación de ASYD.

<br/>
Estructura de los Deploys:
-----------------
<br/>

* Un directorio llamado con el nombre de deploy (i.e. `data/deploys/LAMP/`). Este nombre
se mostrará en la interfaz web de ASYD en las sección "Deploys".
* Un archivo "def" (i.e. `data/deploys/LAMP/def`) con la definición de lo que el deploy hará:
paquetes a instalar, comandos para ejecutar, configuraciones a cargar, condiciones, etc.
* Opcionalmente un archivo "def.sudo" (i.e. `data/deploys/LAMP/def.sudo`) en caso de que queramos
ejecutarlo en lugar del archivo estándar "def" cuando usamos un usuario no root.
* Opcionalmente un archivo "undeploy" (i.e. `data/deploys/LAMP/undeploy`) con los pasos necesarios para
revertir los cambios hechos por un Deploy.
* Opcionalmente un archivo "undeploy.sudo" (i.e. `data/deploys/LAMP/undeploy.sudo`) siendo el equivalente
de "def.sudo" para "undeploy".
* Un directorio de "configs" con todos los archivos y carpetas de configuración que quieres cargar
(i.e. `data/deploys/LAMP/configs/apache/apache.conf`).

** Nota sobre "def.sudo":** este archivo de definición se ejecutará en lugar del archivo normal "def" sólo en caso
de que el usuario que esté ejecutando en el equipo remoto no sea "root" y este archivo esté presente.
Es especialmente útil en máquinas Ubuntu las cuales no tienen usuario root.
Para las máquinas en las que el usuario es "root",  el archivo estándar "def" será el ejecutado a pesar de la existencia de "def.sudo".
Si este archivo no está presente, el archivo estándar "def" será ejecutado también para usuarios no root. Lo mismo se aplica a "undeploy.sudo".

<br/>
El archivo "def":
------------------
<br/>
Tanto el archivo "def" como el archivo "def.sudo", usados para definir un deploy, aceptan los siguientes
comandos y parámetros. Las mismas reglas también se aplican a los archivos "undeploy" y "undeploy.sudo".

*Ten en cuenta que los dos puntos - : - después de los condicionales y antes
de los argumentos, es imprescindible para el funcionamiento del deploy.*

**0. comentarios**

Cualquier línea que empiece con una almohadilla (#) es interpretada como un comentario y no será ejecutada
Hay un tipo especial de comentario, la alerta, la cual despliega un mensaje de alerta antes de lanzar el deploy,
esto es útil en el caso de que tu deploy requiera alguna variable personalizada o quieras avisar al usuario para que compruebe
algo en concreto antes de ejecutar el deploy. Tenga en cuenta que las alertas solo funcionan en los archivos "def", y no en los "def.sudo".
Las alertas se crean empezando la línea con `# alert:`

*Sintaxis:* `# Comentario normal`

*Sintaxis:* `# Alert: Mensaje que se desplegará antes de confirmer la ejecución de un deploy`

**1. install / uninstall**
El comando install puede ser usado para definir (separadas por espacios) listas de paquetes a ser instalados
en el sistema seleccionado. Internamente, ASYD comprobará el tipo de sistema en el cual van a instalarse
los paquetes y usará el gestor de paquetes adecuado para ello. Opcionalmente puedes definir
condicionales - Por favor lee la sección [Conditionals](conditionals.md) de la documentación para información de uso.
En sistemas Solaris también acepta un argumento extra para definir el gestor de paquetes, lee la sección
de [Solaris](solaris.md) de la documentación para información más detallada.

*Sintáxis:* `install [if <condition>]: package_a package_b package_c`

El comando uninstall actua como el comando install, pero para eliminar paquetes de software.
También acepta opcionalmente condicionales y gestor de paquetes en el caso de Solaris.

*Sintáxis:* `uninstall [if <condition>]: package_a package_b package_c`

**2. config file**

Este comando te permite cargar una configuración almacenada en el directorio "configs" (primer parámetro)
a la trayectoria definida para el host de destino (segundo parámetro). El nombre del archivo local debe ser
escrito como es llamado dentro del directorio "configs" del deploy, pero puedes usar cualquier nombre
de destino ya que será renombrado. Opcionalmente también acepta condicionales
y un argumento "noparse" en caso de que no quieras que el archivo de configuración sea parseado antes de cargarlo
sino que sea cargado como está escrito. Por favor lee también la sección de [Configurations](configurations.md) de la documentación.

*Sintáxis:* `[noparse] config file [if <condition>]: file.conf, /destination/file.conf`

**3. config dir**

Se comporta de la misma forma que el comando "config file", pero inspecciona recursivamente todos los archivos y
subdirectorios en el interior del directorio definido, parseando cada uno de los archivos de configuración que hay en él.
Como para el "config file", también accepta opcionalmente condicionales y el parámetro "noparse" (lee "config file" arriba).

*Sintáxis:* `[noparse] config dir [if <condition>]: confdir, /destination/dir`

**4. exec**

Este comando simplemente ejecuta cualquier comando de usuario definido (bash/sh), este es el comándo
más versátil de ASYD. Accepta opcionalmente condicionales y también parámetro host, en el que puedes
especificar cualquier otro host en el que el comando debería ser ejecutado, en lugar del target del deploy
(por ejemplo si quieres actualizar una base de datos o realizar cualquier acción en un host definido
cada vez que un nuevo sistema es deployeado). El comando "exec" también acepta cualquier variable en el comando definido
de forma que puedas incluir contraseñas, parámetros variables, información de sistema, etc. como parámetros
para cualquier comando.

*Sintáxis:* `exec [host] [if <condition>]: command`

**5. http**

Este comando te permite ejecutar una petición HTTP GET o POST desde un deploy. Esta llamada la realiza
el servidor ASYD en lugar del host que está siendo deployeado. Esto es particularmente útil para interactuar
con una API, dado que puedes usar "http" desde el comando "var" y guardar la respuesta en una variable (vease el siguiente punto).

*Sintáxis:* `http get [if <condition>]: url`

*Sintáxis:* `http post [if <condition>]: url[, key1=val1, key2=val2, ...]`

**6. var**

Este comando te permite asignar una variable de host desde un archivo "def" o "undeploy", la cual puede ser
llamada luego como una variable normal (<%VAR:varname%> - ver [Variables](variables.md)). Las variables pueden
ser asignadas con el resultado de los comandos "exec" - asegurate de que el comando produce una respuesta - o "http".
Si una variable con el mismo nombre existe, el valor será reemplazado por el nuevo.

*Sintáxis:* `var <varname> = exec [host] [if <condition>]: command`

*Sintáxis:* `var <varname> = http <get|post> [if <condition>]: url[, key1=val1, key2=val2, ...]`

**7. monitor / unmonitor**

Este comando te permite monitorizar (o dejar de monitorizar en el caso de "unmonitor") un servicio. El parámetro del servicio debe tener el mismo nombre
que el archivo "monitor" en el interior del directorio `data/monitors`, el cual debe existir. También
puedes especificar distintos servicios separados por espacios. También accepta opcionalmente condicionales.

*Sintáxis:* `monitor [if <condition>]: service`

*Sintáxis:* `unmonitor [if <condition>]: service`

**8. deploy / undeploy**

Con este comando puedes lanzar otros deploys desde un deploy, permitiéndote incluso crear
un meta-deploy definiendo los deploys que deberían ser lanzados dependiendo de los condicionales.
El deploy indicado debe existir. Este comando también accepta opcionalmente condicionales.

*Sintáxis:* `deploy [if <condition>]: another_deploy`

El comando "undeploy" actúa de la misma forma pero usando el archivo `undeploy` en lugar
del archivo `def` usado por los deploys.


*Sintáxis:* `undeploy [if <condition>]: another_deploy`

**9. reboot**

Este comando simplemente reinicia un sistema. Este comando no requiere el doble punto - : - y el único
parámetro opcional permitido es un condicional. **Date cuenta** de qué este comando debería siempre
ser usado al final del deploy, de otra forma, el servidor ASYD perderá la comunicación con el
host destino y los siguientes comandos no serán ejecutados.

*Sintáxis:* `reboot [if <condition>]`
