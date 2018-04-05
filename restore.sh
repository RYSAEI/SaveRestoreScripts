#!/bin/bash

# Valido parámetros
if [ $# -eq 0 ];
then
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
CONFIGS_DIR=$1

# Chequea si es el directio actual
# o la ruta es relativa.
# Sino deja la absoluta pasada por parámetro
if [ "${#CONFIGS_DIR}" -eq "1" ] && [ "${CONFIGS_DIR:0:1}" = "." ]; then
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
  cmd_base="/usr/sbin/vcmd -c $CORE/$node -- "
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
