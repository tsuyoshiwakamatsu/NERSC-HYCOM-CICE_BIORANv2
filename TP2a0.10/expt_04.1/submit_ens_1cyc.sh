#!/bin/bash
set -u

# initialize the job

rm -rf log SCRATCH

# Ensemble run setups

gdnow=$1
gdnxt=$2
jid0=$3

START=$(date -d "$gdnow" +"%Y-%m-%dT00:00:00")
END=$(date -d "$gdnxt" +"%Y-%m-%dT00:00:00")

# Hycom setups in common_ran.src

tsecnow=$(date -d "$gdnow" +%s)
tsecnxt=$(date -d "$gdnxt" +%s)
diff_sec=$((tsecnxt - tsecnow))

rstrfq=$((diff_sec / 86400)) # restart file dumping frequency [day], dumped only at the end.
meanfq=1                     # archive file (average) dumping frequency [day]

cat ./FILES/common_ran.src | \
    sed -e "s/^export MEANFQ=[0-9]\+/export MEANFQ=$meanfq/" \
        -e "s/^export RSTRFQ=[0-9]\+/export RSTRFQ=$rstrfq/" \
    > common_ran.src

# check include files

[ -f common_ran.src ] || { echo "Could not find common_ran.src "; exit 1; } 
[ -f common_ens.src ] || { echo "Could not find common_ens.src "; exit 1; } 

# Submit job

mkdir -p log
jid1=$(sbatch --dependency=afterok:$jid0 srjob_prep_ens.sh $START $END | sed 's/Submitted batch job //')
jid2=$(sbatch --dependency=afterok:$jid1 srjob_hyc_ens.sh | sed 's/Submitted batch job //')
jid3=$(sbatch --dependency=afterok:$jid2 srjob_post_ens.sh $START $END | sed 's/Submitted batch job //')
echo $jid3

exit $?
