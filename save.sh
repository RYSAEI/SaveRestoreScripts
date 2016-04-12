#!/bin/bash

# TODO: Tener en cuenta varias instancias de Core ejecutando y diferenciarlas (actualmente soporta solo una instancia).
# TODO: Buscar mejor forma de diferenciar entre router y pc (tanto cuando se salva como cuando se restaura).
# TODO: Aceptar como argumento nombre de carpeta destino (analizar en save y restore).
# NOTA: Tengo el pid de cada topología cuando la enciendo... ;)
SOCKETS_DIR=$(ps aux | grep -oP "/tmp/pycore.[0-999999999999999].+?(?=/)" | head -n 1)
OUTPUT_DIR='configs'
mkdir $OUTPUT_DIR
find "$SOCKETS_DIR" -maxdepth 1 | while read file; do
	if [ -S $file ]; then
		output_file=$(pwd)/$OUTPUT_DIR/$(basename $file).run
		output=$(/usr/sbin/vcmd -c $file -- vtysh  -E -c 'show run' 2>/dev/null | tail -n+5 )
		# Como desconozco el servicio o no sé cuál es router o no, pregunto si se genera una salida. Es una solución temporal.
		if  [ ${#output} -ne 0 ]
		then
			echo -e "$output" > $output_file
		else
			ip_net_addr=$(/usr/sbin/vcmd -c $file -- bash -E -c 'ip -f inet -o addr')
			route_n=$(/usr/sbin/vcmd -c $file -- bash -E -c 'route -n')
			echo -e "$ip_net_addr" | awk '{print "ifconfig "$2" "$4}' | grep eth > $output_file
			echo -e "$route_n" | awk '{if ($1 == "0.0.0.0") print "route add default gw "$2}' >> $output_file
		fi
		echo "Saving $(basename $file)"
	fi
done
echo "Finish"

exit 0
