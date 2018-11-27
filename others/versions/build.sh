#!/bin/bash
export GC_INITIAL_HEAP_SIZE=18G
for file in *.p4
do
    if ! [ -f $file.json ]
    then
        p4c-bm2-ss --p4v 16 "$file" -o "$file.json"
    fi
done
