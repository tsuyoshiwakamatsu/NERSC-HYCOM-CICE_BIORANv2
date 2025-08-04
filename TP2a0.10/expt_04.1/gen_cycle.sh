#!/bin/bash

# Starting year and date
start_year=$1
start_date="${start_year}0101"

new_year=$((start_year + 1))
new_date="${new_year}0101"

# Define the output file name
mkdir -p lists
output_file="./lists/list_${start_year}.txt"

[ -f $output_file ] && rm -f $output_file

# Initialize the date counter
counter=0

# Loop to generate the dates for the entire year
while true; do
  # Format the date
  formatted_date=$(date -d "${start_date} +$((7 * counter)) days" +"%Y%m%d")
  
  # Check if the date is still within the same year
  if [[ $(date -d "$formatted_date" +"%Y") -ne $start_year ]]; then
    break
  fi

  # Print the date and index to the output file
  echo "$counter $formatted_date" >> $output_file
  
  # Increment the counter
  ((counter++))
done
echo "$counter $new_date" >> $output_file

# Print a message indicating that the file was created
echo "File $output_file created with dates for the year $start_year."
