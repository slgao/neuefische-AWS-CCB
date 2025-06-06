#!/bin/bash

echo "What is the name of the file you are looking for?"
read file_name
# Check if the file exists by the given name
if test -f $file_name; then
    echo "The file $file_name exists."
else
    echo "The file $file_name does not exist"
fi
