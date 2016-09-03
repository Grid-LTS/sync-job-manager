#!/bin/bash

DIRFILE="dirs"

if [ -e $DIRFILE ]; then
	while read source target; do
		echo $source
		echo $target
	done < $DIRFILE
	echo "preparing to delete files" >&2
fi
