#!/bin/bash

# TODO: Tener en cuenta varias instancias de Core ejecutando y diferenciarlas (actualmente soporta solo una instancia).
# NOTA: Tengo el pid de cada topología cuando la enciendo... ;)

# Valido parámetros
if [ $# -eq 0 ];
then
	echo "Debe especificar la ruta de destino." && exit 1
fi

# Obtengo instancia de CORE (por ahora sólo una)
SOCKETS_DIR=$(ps aux | grep -oP "/tmp/pycore.[0-9]+" | head -n 1)

# Ruta pasada como argumento
OUTPUT_DIR=$1

# Chequea si es el directio actual
# o la ruta es relativa.
# Sino deja la absoluta pasada por parámetro
if [ "${#OUTPUT_DIR}" -eq "1" ] && [ "${OUTPUT_DIR:0:1}" = "." ];
then
	# es directorio actual
	OUTPUT_DIR="$PWD/"
elif [ "${OUTPUT_DIR:0:1}" != "/" ]; then
	# es relativo
	OUTPUT_DIR="${PWD}/$OUTPUT_DIR/"
else
	OUTPUT_DIR="$1/"
fi

# Creo el directorio donde se guardará la configuración
mkdir -p $OUTPUT_DIR

function _is_router() {
	`/usr/sbin/vcmd -c $1 -- vtysh -c 'show run' &>/dev/null`
	return $?
}

function ok() {
	echo -e "$1: \e[32mOK\e[0m"
}

function fail() {
	echo -e "$1: \e[31mFAIL\e[0m"
}

function persist() {
	echo -e "$1" > $2 && ok $2 || fail $2
}

# Proceso la instancia de Core
for file in $SOCKETS_DIR/*; do
	# Verifico que el archivo sea un Socket
	if [ -S $file ];
	then
		# Obtengo nombre del archivo
		filename="$(basename $file)"
		# Obtengo path absoluto del archivo a guardar
		output_file="${OUTPUT_DIR}${filename}"
		# Verifico si es un router
		if (_is_router $file);
		then
			config=`/usr/sbin/vcmd -c $file -- vtysh -E -c 'show run' 2>/dev/null | tail -n+5`
			# Persisto e imprimo el resultado de la operación
			persist "$config" "$output_file.vtysh"
		fi
		# Configuración de interfaces eth*
		ip_net_addr=`/usr/sbin/vcmd -c $file -- bash -E -c 'ip -f inet -o addr' | awk '{print "ifconfig "$2" "$4}' | grep eth`
		# Tabla de Ruteo
		route_n=`/usr/sbin/vcmd -c $file -- bash -E -c 'route -n' | awk '{if ($1 == "0.0.0.0") print "route add default gw "$2}'`
		config=$ip_net_addr"\n"$route_n
		# Persisto e imprimo el resultado de la operación
		persist "$config" "$output_file.bash"
	fi
done
