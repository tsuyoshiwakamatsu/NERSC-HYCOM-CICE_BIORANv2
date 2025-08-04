#!/bin/bash
set -u

START=$1
END=$2

source common_ran.src || { echo "Could not source common_ran.src "; exit 1; } #use INITFLAG

# Configure INITFLAG, REGION.src, EXPT.src and blkdat.input for restart run
echo "=========================================================="
echo " prep_config_rst.sh"
echo "=========================================================="
bash prep_config_rst.sh ||{ echo "prep_config_rst had fatal errors "; exit 1; } #> /dev/null 2>&1

# Transfer nesting and restart files to data
echo "=========================================================="
echo " prep_inputs_rst.sh $START $END"
echo "=========================================================="
bash prep_inputs_rst.sh $START $END ||{ echo "prep_inputs_rst had fatal errors "; exit 1; } #> /dev/null 2>&1

# Generate atmospheric forcing
echo "=========================================================="
echo " atmo_synoptic.sh era5 $START $END"
echo "=========================================================="
bash atmo_synoptic.sh era5 $START $END ||{ echo "atmo_synoptic had fatal errors "; exit 1; } #> /dev/null 2>&1

# Transfer files to SCRATCH
echo "=========================================================="
echo " prep_scratch.sh $START $END $INITFLAG"
echo "=========================================================="
bash prep_scratch.sh $START $END $INITFLAG || { echo "prep_scratch had fatal errors "; exit 1; } #> /dev/null 2>&1
