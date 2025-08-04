#!/bin/bash

# Check if the correct number of arguments is provided

if [ "$#" -ne 3 ]; then
   if [ "$#" -eq 1 ]; then
      year=$1
      if ! [[ "$year" =~ ^[0-9]{4}$ ]]; then
         echo "$year is not a 4-digit integer."
         echo "Usage: $0 <year>"
         echo "Usage: $0 <year> <start_index> <end_index>"
         exit 1
      fi
   else
      echo "Usage: $0 <year>"
      echo "Usage: $0 <year> <start_index> <end_index>"
      exit 1
   fi
else
   year=$1
   start_index=$2
   end_index=$3
fi

# Input file
input_file="./lists/list_$year.txt"

if [ ! -f $input_file ]; then
    echo "Can not find cycle file: $input_file, try bash gen_cycle.sh $year"
    exit 1
fi

# Read the entire file into an array
mapfile -t lines < "$input_file"

# Get the number of lines in the file
num_lines=${#lines[@]}

if [ "$#" -eq 1 ]; then
   start_index=1
   end_index=$num_lines
fi

# Validate indices
if ! [[ "$start_index" =~ ^[0-9]+$ ]] || ! [[ "$end_index" =~ ^[0-9]+$ ]] || [ "$start_index" -gt "$end_index" ]; then
    echo "Invalid indices. Make sure start_index and end_index are positive integers and start_index <= end_index."
    exit 1
fi

# Ensure start_index and end_index are within the valid range
if [ "$start_index" -ge "$num_lines" ] || [ "$end_index" -gt "$num_lines" ]; then
    echo "Indices out of range. The file has only $num_lines lines."
    exit 1
fi

# Loop over the indices from start_index to end_index
for i in $(seq "$start_index" "$end_index"); do
    # Extract the current and next lines
    current_line=${lines[$i - 1]}  # Lines are zero-indexed in the array
    if [ "$i" -lt "$end_index" ]; then
        next_line=${lines[$i]}
        # Extract dates from the current and next lines
        gdnow=$(echo $current_line | awk '{print $2}')
        gdnxt=$(echo $next_line | awk '{print $2}')
        # Print or process the dates
        echo "$i: $gdnow $gdnxt"
    fi
done
