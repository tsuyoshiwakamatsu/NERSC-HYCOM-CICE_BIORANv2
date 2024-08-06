#!/bin/bash
set -u

# Set integration period

gdnow=20160115
gdnxt=20160122

START=$(date -d "$gdnow" +"%Y-%m-%dT00:00:00")
END=$(date -d "$gdnxt" +"%Y-%m-%dT00:00:00")

# Configure INITFLAG, REGION.src, EXPT.src and blkdat.input for restart run
bash ../bin/prep_config_rst.sh             > /dev/null 2>&1

# Prepare nesting and restart files
bash ../bin/prep_inputs_rst.sh $START $END > /dev/null 2>&1

# Submit job
sbatch srjob_single.sh $START $END 

