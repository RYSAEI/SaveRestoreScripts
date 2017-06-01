# SaveRestoreScripts
Save/Restore scripts for CORE-GUI network elements

Estos scripts son utilizados por la cátedra de grado: "Redes y Servicios Avanzados en Internet" de la
Facultad de Informática de la Universidad Nacional de La Plata (UNLP)

La primer versión fue aportada por el alumno Mauro Soria en el año 2013.

# Cómo usarlo

**NOTA**: Para que estos scripts funcionen correctamente, se debe tener sólo una instancia de CORE ejecutando en la máquina.

`./save.sh /path/to/save` esto guardará los archivos `*.host` y `*.router` en el directorio pasado por parámetro.

`./restore.sh /path/to/load` esto cargará los archivos anteriormente guardados (`*.host` y `*.router`) del directorio pasado por parámetro.
