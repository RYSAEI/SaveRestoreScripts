#!/bin/bash
SOCKETS_DIR=$(ps aux | grep -oP "/tmp/pycore.[0-999999999999999].+?(?=/)" | head -n 1)
CONFIGS_DIR='configs'

rm start.sh
find "$CONFIGS_DIR" -maxdepth 1 -type f | while read file; do
	FILENAME=$(basename "$file")
	NODE=${FILENAME%.*}
	# Tenemos que decidir cuándo es un router y cuándo no (en los .run los routers empiezan con "!"):
	first_line=$(head -1 $file)
	if [ "$first_line" == "!" ]
	then
		ARGUMENT="/usr/sbin/vcmd -c $SOCKETS_DIR/$NODE -- vtysh -E  "
		ARGUMENT+="-c 'conf t'"
		while read line 
		do
			ARGUMENT+=" -c '$line'"
		done < "$file"
		echo  $ARGUMENT >> start.sh
	else
		while read line
		do
			echo "/usr/sbin/vcmd -c $SOCKETS_DIR/$NODE -- bash -E -c '$line'" >> start.sh
		done < "$file"
	fi
done
bash start.sh
rm start.sh

