#!/bin/bash
set -u

START=$1
END=$2

echo "=========================================================="
echo " prep_det.sh $START $END"
echo "=========================================================="
# Configure INITFLAG, REGION.src, EXPT.src and blkdat.input for restart run
# Transfer nesting and restart files to data
# Generate atmospheric forcing
# Transfer files to SCRATCH
bash prep_det.sh $START $END || { echo "prep_det had fatal errors "; exit 1; }

# Prepare ensemble files under ensemble SCRATCH
echo "=========================================================="
echo " init_ens.sh $START"
echo "=========================================================="
bash init_ens.sh $START || { echo "init_ens had fatal errors "; exit 1; }
