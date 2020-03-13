# SaveRestoreScripts
Save/Restore scripts for CORE-GUI network elements

Estos scripts son utilizados por la cátedra de grado: "Redes y Servicios Avanzados en Internet" y "Redes y Comunicaciones" de la
Facultad de Informática de la Universidad Nacional de La Plata (UNLP)

La primer versión fue aportada por el alumno Mauro Soria en el año 2013.

# Cómo usarlo

**NOTA**: Se agregó soporte para trabajar con más de una instancia de CORE.

Para esto se debe especificar con cual instancia de CORE se debe trabajar, esto
se puede hacer mediante el el número que se muestra en la barra superior del
programa.

`save.sh /path/to/save` esto guardará los archivos `*.bash` y `*.vtysh` en el directorio pasado por parámetro.

`restore.sh /path/to/load` esto cargará los archivos anteriormente guardados (`*.bash` y `*.vtysh`) del directorio pasado por parámetro.
