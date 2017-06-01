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
else
	CONFIGS_DIR=$1
fi

function ok() {
	echo -e "$1: \e[32mOK\e[0m"
}

function fail() {
	echo -e "$1: \e[31mFAIL\e[0m"
}

for file in $CONFIGS_DIR/*; do
	filename=$(basename "$file")
	cmd_type="${filename##*.}"
	node=${filename%.*}
	# Uso vcmd para comunicarme con el socket (nodo)
	cmd_base="/usr/sbin/vcmd -c $SOCKETS_DIR/$node -- "
	case $cmd_type in
		"vtysh")
			cmd="$cmd_base vtysh -E -c 'conf t'"
			# Verificamos si BGP está habilitado.
			bgp_number=$( eval "$cmd -c 'do sh run'" | grep "router bgp" | awk '{ print $NF }' )
			if [ ${#bgp_number} -ne 0 ]; then
				eval "$cmd -c 'no router bgp $bgp_number'" &>/dev/null
			fi
			# Leo las lineas del archivo
			# y se las envio como comandos concatenados
			while read line; do
				cmd+=" -c '$line'"
			done < "$file"
			# Ejecuto comando concatenado
			eval $cmd &>/dev/null
			;;
		"bash")
			cmd="$cmd_base bash -E -c "
			while read line; do
				eval "$cmd '$line'" &>/dev/null
			done < "$file"
			;;
	esac
done
ok "Loaded"
