#!/bin/bash

# Valido parámetros
if [ $# -eq 0 ];
then
	echo "Debe especificar la ruta de destino." && exit 1
fi

# Obtengo instancia de CORE (por ahora sólo una)
SOCKETS_DIR=$(ps aux | grep -oP "/tmp/pycore.[0-9]+" | head -n 1)

# Ruta pasada como argumento
CONFIGS_DIR=$1

# Chequea si es el directio actual
# o la ruta es relativa.
# Sino deja la absoluta pasada por parámetro
if [ "${#CONFIGS_DIR}" -eq "1" ] && [ "${CONFIGS_DIR:0:1}" = "." ];
then
	# es directorio actual
	CONFIGS_DIR="$PWD/"
elif [ "${CONFIGS_DIR:0:1}" != "/" ]; then
	# es relativa
	CONFIGS_DIR="${PWD}/$CONFIGS_DIR/"
fi

function ok() {
	echo -e "$1: \e[32mOK\e[0m"
}

function fail() {
	echo -e "$1: \e[31mFAIL\e[0m"
}

for file in $CONFIGS_DIR/*; do
	filename=$(basename "$file")
	node_type="${filename##*.}"
	node=${filename%.*}

	# Comando Base para comunicarme con los sockets
	cmd="/usr/sbin/vcmd -c $SOCKETS_DIR/$node --"

	case $node_type in
		"router")
			# Si es un router usaré vtysh
			cmd="$cmd vtysh -E -c 'conf t' "
			;;
		"host")
			# Si es un host bash
			cmd="$cmd bash -E "
			;;
	esac

	# Concateno los comandos a ejecutar
	while read line; do
		cmd+=" -c '$line'"
	done < "$file"

	# Ejecuto el comando de un tiro
	eval $cmd &>/dev/null && ok $file || fail $file
done
