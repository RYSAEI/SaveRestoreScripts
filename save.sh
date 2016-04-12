#!/bin/bash
SOCKETS_DIR=$(ps aux | grep -oP "/tmp/pycore.[0-999999999999999].+?(?=/)" | head -n 1)
OUTPUT_DIR='configs'
mkdir $OUTPUT_DIR
find "$SOCKETS_DIR" -maxdepth 1 | while read file; do
	if [ -S $file ]; then
		/usr/sbin/vcmd -c $file -- vtysh  -E -c 'show run' 2>/dev/null | tail -n+5 > $(pwd)/$OUTPUT_DIR/$(basename $file).run
		echo "Saving $(basename $file)"
	fi
done
echo "Finish"
