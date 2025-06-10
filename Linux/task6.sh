#!/bin/bash

# Base name and extension
base_name="file"
ext=".txt"

# Function to find the next available file name
get_next_filename() {
    counter=0
    while true; do
        if [ $counter -eq 0 ]; then
            filename="${base_name}${ext}"
        else
            filename="${base_name}${counter}${ext}"
        fi

        if [ ! -e "$filename" ]; then
            echo "$filename"
            return
        fi
        ((counter++))
    done
}

while true; do
    echo "Do you want to create a new file?"
    read answer
    # If the answer is yes, check the current folder to see if there is already existing files,
    # the files can be by default created with an incremented number.
    # if [[ $answer =~ ^(yes|y|no|n)$ ]]; then
    if [[ $answer =~ ^(y|yes)$ ]]; then
        # Create file
	filename=$(get_next_filename)
        touch $filename
        echo "File created: $filename"
    elif [[ $answer =~ ^(n|no)$ ]]; then
        # Stop here
	echo "Stop creating file and exit!"
        break
    else
	echo "Please answer yes/y/no/n!"
    fi	
done


