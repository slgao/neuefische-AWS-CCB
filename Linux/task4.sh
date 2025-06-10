#!/bin/bash

echo "Enter the first number:"
read first
echo "Enter the second number:"
read second
if [ $first -gt $second ]
then 
    echo "the first number is greater than the second number."
elif [ $first -lt $second ]
then
    echo "the second number is greater than the first number."
elif [ $first -eq $second ]
then
    echo "the numbers are equal."
fi
