#!/bin/bash
SOCKETS_DIR=$(ps aux | grep -oP "/tmp/pycore.[0-999999999999999].+?(?=/)" | head -n 1)
CONFIGS_DIR='configs'

rm start.sh
find "$CONFIGS_DIR" -maxdepth 1 -type f | while read file; do
	FILENAME=$(basename "$file")
	NODE=${FILENAME%.*}
	ARGUMENT="/usr/sbin/vcmd -c $SOCKETS_DIR/$NODE -- vtysh -E  "
	ARGUMENT+="-c 'conf t'"
	while read line 
	do
		ARGUMENT+=" -c '$line'"
	done < "$file"
	echo  $ARGUMENT >> start.sh
done
bash start.sh
rm start.sh

