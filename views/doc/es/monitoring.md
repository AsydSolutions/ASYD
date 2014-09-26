Monitorización
==============
<br/>
La monitorización de servidores y servicios en ASYD es llevada a cabo por [monit](http://mmonit.com/monit/).
El servidor ASYD comprueba la instalación local en el host remoto para
cualquier cambio en el estado del servidor o cualquiera de los servicios que están siendo monitorizados.

<br/>
Instalación
------
<br/>
La monitorización se instala automáticamente en cada host que se añade a ASYD usando un "deploy"
el cual instala y configura **monit** en todos los sistemas soportados.

Puedes encontrar este "deploy" en `data/deploys/monit/` depués de que la instalación inicial haya acabo.
También puedes modificar este deploy de acuerdo a tus necesidades, por favor lee la sección [Deploys](deploys.md)
de la documentación.

<br/>
Monitors
--------
<br/>
Los monitors son archivos de configuración estándar de monit definidos para cada sevicio.

Estos archivos son almacenados bajo `data/monitors/` y aceptan condicionales y variables
como para cualquier otro archivo de configuración (lee [Configurations](configurations.md) en la documentación), permitiendo
escribir un solo archivo de monitorización para cualquier tipo de host.

El nombre del archivo para el archivo de monitorización debe tener el mismo nombre que el servicio que está siendo monitorizado
(por ejemplo, para monitorizar nginx debe nombrar el archivo de monitorización como `data/monitors/nginx`)

Puedes monitorizar servicios

1. Usando el comando "monitor" en un archivo "def".
2. Poniendo en cualquier archivo de configuración la etiqueta `<%MONITOR:service%>` donde service es el nombre
del servicio tal y como esta escrito en el nombre del archivo del monitor.
