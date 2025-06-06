#!/bin/bash

src_dir=$(realpath "$1")
des_dir=$(realpath "$2")

# Check if two arguments are provided, and they are both directories 
if [ ! -d "$src_dir" ]; then
    echo "The source directory is not provided!"
    exit 1
fi
# If the arguments meet the previous requirements, do the work
# Check if the destination directory exists, if not, create one.
if ! [ -d $des_dir ]; then
    mkdir -p $des_dir
fi
# If the destination directory is in the source directory, echo error
if [[ "$des_dir" == "$src_dir"* ]]; then
    echo "Error: Destination cannot be inside the source directory!"    
    exit 1
fi
# Copy all the files from the source directory to the destination directory.    
cp -a "$src_dir"/. "$des_dir"
echo "Backup completed successfully to: \"$des_dir\""
