#!/bin/bash

dir=$1
num_files=$2

# Check if the two mandatory arguments are provided
if ! [[ $# == 2 ]]; then
    echo "Usage: $0 [directory] [number-of-files]"
    exit 1
elif [ ! -d $dir ] || ! [[ $num_files =~ ^[0-9]+$ ]]; then
    echo "Usage: $0 [directory] [number-of-files]"
    exit 1
else
    for i in $(seq 1 $num_files); do
        touch $dir/file_$i.txt 
    done 
fi

