#!/bin/bash
prefix=$(users)
# Check the current folder, get the maximum number from the existing files.
file_list=$(ls | grep -E "^${prefix}[0-9]+$")

max_number=0
for file in $file_list; do
    number=${file#$prefix} # Remove the prefix
    if [[ $number =~ ^[0-9]+$ ]]; then
        (( number > max_number )) && max_number=$number
    fi
done
    
# Determine starting file number
if [ -z $max_number ]; then
    start=1
else
    start=$(($max_number + 1))
fi

# Number of files to create
num_files=25

# Create files
for ((i=0; i<$num_files; i++)); do
    file_name="${prefix}$(($start + i))"
    touch "$file_name"
done

# List the created files.
echo "Files are created!"
ls -l ${prefix}[0-9]*
