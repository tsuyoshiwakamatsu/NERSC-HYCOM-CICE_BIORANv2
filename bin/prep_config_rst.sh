#!/bin/bash
set -u

source ran_common_rst.src || { echo "Could not source ./common_ran.src "; exit 1; }

# Configure REGION.src

cd $WORK_HYCOM/$CONFIGNAME
cp $HOME_HYCOM/${HYCOM_REPO}/input/REGION.src .
sed -i "/^export R=/c export R=$CONFIGNAME" REGION.src
sed -i "/^export NHCROOT=/c export NHCROOT=$HOME_HYCOM/${HYCOM_REPO}" REGION.src

# Configure EXPT.src

cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT
#echo ""                                                >> EXPT.src
#echo "# add new parameters for FABM and ICE"           >> EXPT.src
#echo "export MXBLCKS=${MXBLCKS}"                       >> EXPT.src # maximal number of ice blocks 
#echo "export COMPILE_BIOMODEL=\"${COMPILE_BIOMODEL}\"" >> EXPT.src # FABM coupler ON ("yes") or OFF ("no")
sed -i "/^T=/c T=\"$T\"" EXPT.src                                  # topography version
sed -i "/^export NMPI=/c export NMPI=$NMPI" EXPT.src
sed -i "/^export MXBLCKS=/c export MXBLCKS=$MXBLCKS" EXPT.src
sed -i "/^export COMPILE_BIOMODEL=/c export COMPILE_BIOMODEL=\"${COMPILE_BIOMODEL}\"" EXPT.src

# Configure blkdat.input

cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT
if [ -f blkdat.input_expt04.2 ]; then
   cp blkdat.input_expt04.2 blkdat.input
else
   cp /cluster/projects/nn9481k/shuang/Files_cp_other/blkdat.input_expt04.2 blkdat.input
fi
filename='blkdat.input'
# Define a dictionary (an associative array) of keyword and replacement.
# Note length of keyword inside of a bracket [""] is fixed to 6 including blanks.
declare -A replacements=( 
    ["iexpt "]="$IEXPT"  # experiment number
    ["relax "]="$RELAX"  # physics relaxation: 0-relaxation off; 1-relaxation on
    ["ntracr"]="$NTRACR" # BGC on/off: 0-physics only; 1-biology restart; -1-biology initialized with climatology
    ["trcrlx"]="$TRCRLX" # BGC relaxation: 0-relaxation off; 1-relaxation on
    ["rstrfq"]="$RSTRFQ" # frequency of model restart dump [day] Note: Only integer. Do not use float
    ["lbflag"]="$LBFLAG" # lateral barotropic bndy flag (0=none, 1=port, 2=input)
    ["bnstfq"]="$BNSTFQ" # number of days between baro nesting archive input
    ["nestfq"]="$NESTFQ" # number of days between 3-d  nesting archive input
 )

tempfile=$(mktemp)
while IFS= read -r line; do
    for keyword in "${!replacements[@]}"; do
        replacement="${replacements[$keyword]}"
        if [[ "$line" == *"$keyword"* ]]; then
            line=$(echo "$line" | sed -E "s/^([[:space:]]*)(-?[0-9]+)/\1$replacement/")
            break
        fi
    done
    echo "$line" >> "$tempfile"
done < "$filename"
mv "$tempfile" "$filename"
