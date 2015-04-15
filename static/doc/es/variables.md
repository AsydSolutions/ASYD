Variables
=========
<br/>
ASYD ofrece un set de variables globales, relacionada con la información del host, y ofrece
la posibilidad de crear tus propias variables personalizadas (lee "[Basics](basics.md) - Añadiendo host y grupos de host"
en la documentación).

Puedes usar cualquiera de estas variables en cualquier archivo de configuración, archivo de definición de un deploy,
en las condiciones para los condicionales y en los archivos "monitor" para monitorizar servicios, y ellos
automaticamente quedan substituidos (a menos que sea declarado con el parámetro o etiqueta "noparse"). Todas
las variables no distinguen máyusculas y minísculas, lo que quiere decir que`<%IP%>` y `<%ip%>` devolverán el mismo valor.

<br/>
Variables globales:
-------------------
<br/>

    <%ASYD%> - ASYD server IP

    <%HOSTNAME%> - Target host name

    <%IP%> - Target host IP

    <%DIST%> - Target host linux distribution

    <%DIST_VER%> - Target host distribution version

    <%ARCH%> - Target host architecture

    <%PKG_MANAGER%> - Target host package manager

    <%MONITOR:service%> - Not really a variable, monitors the service 'service'

<br/>
Variables personalizadas:
-----------------
<br/>
Puedes definir variables personalizadas tanto en hosts como en grupos de hosts. Puedes también anular el valor
de una variable definida en un grupo de host definiendo la misma variable en un host.

    <%VAR:varname%> - Use the value assigned to "varname"
