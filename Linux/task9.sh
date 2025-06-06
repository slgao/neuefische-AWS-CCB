#!/bin/bash

echo "Please give a direcotry path"
read dir
# Expand the tilde character to home directory
expanded_dir=$(eval echo "$dir")
# Check if the path exists
if [ ! -d "$expanded_dir" ]; then
    echo "Error: Directory does not exist!"
    exit 1
fi

full_path=$(realpath "$expanded_dir")
echo "full path provided is: \"$full_path\""
# Calculate the total size of all files
echo "The total size of all files is $(du -sh "$full_path" | cut -f1)"
