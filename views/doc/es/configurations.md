Configuraciones
==============
<br/>
Las configuraciones son una parte clave en ASYD, puedes poner cualquier archivo o carpeta dentro del directorio "configs"
en un deploy, y entonces cargarlos usando el archivo "def" del deploy.

Cualquier archivo de configuración será parseado buscando variables o condicionales, lo cual da mucha
flexibilidad a la hora de deployear y configurar sistemas. Además, los archivos de configuración dentro de
las carpetas y subdirectorios de configuración serán también recursivamente parseados y cargados.

Puedes anular globalmente este comportamiento añadiendo el parámetro "noparse" en el archivo "def"
cuando cargues un archivo config o config dir (ver [Deploys](deploys.md) en la documentación).
También puedes especificar ciertos bloques de dentro del archivo de configuración que no deberían ser
parseados usando las etiquetas `<%noparse%>` `<%/noparse%>`.

Los condicionales pueden ser usados dentro de los archivos de configuración para definir partes de la configurción que deberían
solo ser incluidos en el host si ciertas condiciones se cumplen. Estos bloques condicionales son definidos dentro de
las etiquetas `<%if condition%>` `<%endif%>` (reempazar "condition" por la condición en sí).
Los condicionales dentro de las etiquetas noparse tampoco son evaluados.

**Importante:** Fíjate que en cada una de estas etiquetas especiales para "noparse" y condicionales deben ser escritas
en una sola línea sin ningún otro carácter en la misma línea, para así funcionar adecuadamente, por ejemplo:

    <%noparse%>
    tags to scape
    <%/noparse%>
    rest of the file

*Lee también la sección de [Variables](variables.md) en la documentación para ver variables disponibles,
y la sección [Conditionals](conditionals.md) para información más detallada sobre el uso de condicionales.*
