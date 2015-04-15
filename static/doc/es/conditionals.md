Condicionales
============
<br/>
Los condicionales son usados para crear reglas para cuando un comando debería ser ejecutado o una configuración
debería ser usada en un host o un grupo de hosts.

Las condiciones válidas son `==` (igual), `!=` (diferente), `>=` (mayor o igual) y `<=` (menor o igual).
Los operadores `>=` y `<=` pueden ser solo usados para números. Los operadores `==` and `!=`  pueden ser ambos usados
para cadenas de texto y números.

Muchos condicionales (tantos como quieras) pueden ser concadenados usando `and` y `or`. Serán
evaluados siguiendo un orden lógico y sequencial (por ejemplo, en `condition1 or condition2` si la primera
condición se cumple, la segunda no será evaluada).

<br/>
Uso:
------
<br/>
**1. Bloques condicionales en "def" files**

Los condicionales pueden ser usados para definir bloques dentro de un archivo "def" que debería ser ejecutado
si una condición se cumple. Ambas, tanto la etiqueta de apertura `if <condition>` y la etiqueta de cierre `endif`
deben ser escritos en una sola línea sin carácteres extra, solo los parámetros aceptados. Entre ellos puedes
escribir cualquier comando que será ejecutado solo si la condición es validada.

*Nota: No puedes definir bloques condicionales dentro de otro bloque condicional, solo uno a la vez.
Puedes, sin embargo, usar condicionales simples dentro de bloques condicionales, como se describe en el siguiente punto.*

*Sintáxis:*

    if <%var%> == value [or|and condition2] [or|and ...]
    [...]
    endif

*Ejemplo:*

    if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_ver%> >= 5
    install: package
    exec: some command
    endif

**2. Comandos en los archivos "def"**

Los condicionales pueden ser usados para comandos sueltos en el interior del archivo "def".  La sintáxis estándar se aplica,
y también puedes definir condiciones para comandos concretos incluso dentro de un bloque condicional (mira arriba)

*Sintáxis:*

    exec if <%var%> == value [or|and condition2] [or|and ...]: some command

*Ejemplo:*

    install if <%DIST%> == debian and <%DIST_VER%> == 6 or <%DIST%> == centos and <%DIST_ver%> >= 5: package

**3.  Bloques condicionales en archivos de configuración**

Los condicionales pueden ser también usados dentro de los archivos de configuración (lee [Configurations](configurations.md) de la documentación)
para definir partes del archivo de configuración que deberían ser solo cargadas en el servidor destino
si la condición se cumple. El uso es el mismo que para bloques condicionales en los archivos "def" (lee arriba)
pero definido por etiquetas `<%if condition%>` `<%endif%>`.

*Nota: No puedes definir bloques condicionales dentro de otro bloque condicional, solo uno a la vez.*

*Sintáxis:*

    <%if <%var%> == value [or|and condition2] [or|and ...]%>
    [...]
    <%endif%>

*Ejemplo:*

    <%if <%DIST%> == debian and <%DIST_VER%> == 6%>
    algunas configuraciones que se aplican solo en Debian 6
    <%endif%>
    <%if <%DIST%> == debian and <%DIST_VER%> >= 7%>
    algunas configuraciones que se aplican solo en Debian 7 o siguientes
    <%endif%>
    configuración común que se aplica en todos los sistemas
