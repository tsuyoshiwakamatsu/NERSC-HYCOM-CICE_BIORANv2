#!/bin/bash
set -u

if [ "$#" -ne 3 ]; then
   echo "Usage: $0 <year> <start_index> <end_index>"
   exit 1
else
   year=$1
   start_index=$2
   end_index=$3
fi

# Input file
input_file="./lists/list_$year.txt"

if [ ! -f $input_file ]; then
    echo "Can not find cycle file: $input_file, try:"
    echo
    echo "   bash gen_cycle.sh $year"
    echo
    echo "before submission."
    exit 1
fi

mapfile -t lines < "$input_file" # Read the entire file into an array
num_lines=${#lines[@]}           # Get the number of lines in the file

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

# Ensemble run setups in common_ens.src

mem1=1
mem2=80
members=$(seq -s ',' $mem1 $mem2)
nens=$(( $(echo "$members" | grep -o ',' | wc -l) + 1 ))

initens_atm="--init"  # "--init"/"--clone"                     ## Atmospheric forcing
initens_rst="--copy"  # "--init"/"--clone"/"--copy"            ## Hycom restart
initens_ice="--copy"  # "--clone"/"--copy"                     ## CICE restart. --init option is not available
initens_bgc="--copy"  # "--init"/"--clone"/"--copy"/"--perturb ## FABM parameters

echo "NENS  $nens"

[ -f common_ens.src ] && rm -rf common_ens.src
echo "export mem1=$mem1"                     >> common_ens.src
echo "export mem2=$mem2"                     >> common_ens.src
echo "export members=$members"               >> common_ens.src
echo "export nens=$nens"                     >> common_ens.src
echo "export initens_atm=\"${initens_atm}\"" >> common_ens.src
echo "export initens_rst=\"${initens_rst}\"" >> common_ens.src
echo "export initens_ice=\"${initens_ice}\"" >> common_ens.src
echo "export initens_bgc=\"${initens_bgc}\"" >> common_ens.src

# Submit job

jid=$(bash submit_jid_init.sh); echo $jid

for i in $(seq "$start_index" "$end_index"); do
    gdnow=$(echo ${lines[$i - 1]} | awk '{print $2}')
    gdnxt=$(echo ${lines[$i]}     | awk '{print $2}')
    START=$(date -d "$gdnow" +"%Y-%m-%dT00:00:00")
    END=$(date -d "$gdnxt" +"%Y-%m-%dT00:00:00")
    echo "$i: $START - $END"
    jid=$(bash submit_ens_1cyc.sh $gdnow $gdnxt $jid); echo $jid
done

exit $?
