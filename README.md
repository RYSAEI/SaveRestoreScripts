# SaveRestoreScripts
Save/Restore scripts for CORE-GUI network elements

Estos scripts son utilidos por la cátedra de grado: "Redes y Servicios Avanzados en Internet" de la 
Facultad de Informática de la Universidad Nacional de La Plata (UNLP)

La primer versión fué aportada por el alumno Mauro Soria en el año 2013.

# Como usarlo

`./save.sh /path/to/save` esto guardará archivos `*.host` y `*.router` en el directorio pasado por parámetro.

`./restore.sh /path/to/load` esto cargará los archivos anteriormente guardados (`*.host` y `*.router`) del directorio pasado por parámetro.

# Retrocompatibilidad 

*Esto sólo es válido para quienes usaban el script antes del 12/04/2016*

Renombrar lso archivos `*.run` por `*.host` y `*.router` dependiendo de si es un host o un router.
