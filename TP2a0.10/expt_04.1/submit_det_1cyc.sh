#!/bin/bash
set -u

# Deterministic run setups

gdnow=$1
gdnxt=$2

START=$(date -d "$gdnow" +"%Y-%m-%dT00:00:00")
END=$(date -d "$gdnxt" +"%Y-%m-%dT00:00:00")

# check include files

[ -f common_ran.src ] || { echo "Could not find common_ran.src "; exit 1; } 

# Submit job

mkdir -p log
jid=$(sbatch srjob_prep_det.sh $START $END | sed 's/Submitted batch job //')
jid=$(sbatch --dependency=afterok:$jid srjob_hyc_det.sh $START $END | sed 's/Submitted batch job //')
jid=$(sbatch --dependency=afterok:$jid srjob_post_det.sh $START $END | sed 's/Submitted batch job //')
echo $jid
