#!/bin/bash

# NOTA: Tengo el pid de cada topología cuando la enciendo... ;)

set -u

# Valido parámetros
if [ $# -eq 0 ]; then
  echo "Debe especificar la ruta de destino." && exit 1
fi

# Obtengo todas las instancias de CORE en forma de array
SOCKETS_DIR=($(ps aux | grep -oP "/tmp/pycore.[0-9]+" | uniq))

# Compruebo si hay más de una instancia de CORE
if [ "${#SOCKETS_DIR[@]}" -gt 1 ]; then

  # Obtengo solamente el id para hacer select
  CORE_IDS=($(echo ${SOCKETS_DIR[@]} | tr -d "[a-zA-Z/.]"))

  echo "Seleccione una instancia de core"
  echo "Ver número de instancia en encabezado de core"
  select core in ${CORE_IDS[@]}; do
    echo "Seleccionó $core"
    CORE=$(ps aux | grep -oP "/tmp/pycore.$core" | uniq)
    break
  done
elif [ "${#SOCKETS_DIR[@]}" -eq 1 ]; then
  CORE=$SOCKETS_DIR
else
  echo "No se encontró ninguna instancia de CORE abierta"
  exit 1
fi

# Ruta pasada como argumento
OUTPUT_DIR=$1

# Chequea si es el directio actual
# o la ruta es relativa.
# Sino deja la absoluta pasada por parámetro
if [ "${#OUTPUT_DIR}" -eq "1" ] && [ "${OUTPUT_DIR:0:1}" = "." ]; then
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
for file in $CORE/*; do
  # Verifico que el archivo sea un Socket
  if [ -S $file ]; then
    # Obtengo nombre del archivo
    filename="$(basename $file)"
    # Obtengo path absoluto del archivo a guardar
    output_file="${OUTPUT_DIR}${filename}"
    # Verifico si es un router
    if (_is_router $file); then
      config=`/usr/sbin/vcmd -c $file -- vtysh -E -c 'show run' 2>/dev/null | tail -n+5`
      # Persisto e imprimo el resultado de la operación
      persist "$config" "$output_file.vtysh"
    fi
    # Configuración de interfaces eth*
    ip_net_addr=`/usr/sbin/vcmd -c $file -- bash -E -c 'ip -f inet -o addr' | awk '{print "ifconfig "$2" "$4}' | grep eth`
    ip6_net_addr=`/usr/sbin/vcmd -c $file -- bash -E -c 'ip  -f inet6 -o addr' | awk '{print "ip -6 add add  "$4" dev "$2}' | grep eth |grep -v fe80`
    # Tabla de Ruteo
    route_n=`/usr/sbin/vcmd -c $file -- bash -E -c 'route -n' | awk '{if ($1 == "0.0.0.0") print "route add default gw "$2}'`
    route6_n=`/usr/sbin/vcmd -c $file -- bash -E -c 'ip -6  route ls' | awk '{if ($1 == "default") print "ip -6 route add default via "$3}'`
    config=$ip6_net_addr"\n"$ip_net_addr"\n"$route_n"\n"$route6_n
    # Persisto e imprimo el resultado de la operación
    persist "$config" "$output_file.bash"
  fi
done
