#!/bin/bash

# Loop through the text files
for file in log/*.stop; do
    # Check if the file contains the string "BADRUN"
    if grep -q "BADRUN" "$file"; then
        # If "BADRUN" is found, print the file name
        echo "$file" | sed -n 's/.*mem\([0-9]\+\)\.stop/\1/p' | sed 's/^0*//'
    fi
done
