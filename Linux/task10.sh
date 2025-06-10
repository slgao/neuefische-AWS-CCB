#!/bin/bash
echo "Please enter a password which has the folliowing criteria:
1. At least 8 characters long
2. Contains at least one uppercase letter
3. Contains at least one lowercase letter
4. Contains at least one number 
5. Contains at least one special character"
read password
if [ ${#password} -lt 8 ]; then
    echo "Password is invalid. - must be at least 8 characters long."
    exit 1
fi    

if ! [[ "$password" =~ [A-Z] ]]; then
    echo "Password is invalid. - must contain at least one uppercase letter."
    exit 1
fi

if ! [[ "$password" =~ [a-z] ]]; then
    echo "Password is invalid. - must contain at least one lowercase letter."
    exit 1
fi

if ! [[ "$password" =~ [0-9] ]]; then
    echo "Password is invalid. - must contain at least one number."
    exit 1
fi

if ! [[ "$password" =~ [^A-Za-z0-9] ]]; then
    echo "Password is invalid. - must contain at least one special character."
    exit 1
fi

echo "Password is valid."
