#!/bin/bash
set -u

# Set integration period

year=$1
newyear=$((year + 1))

if [ $year == 2020 ]; then
  gdnow=${year}0901
else
  gdnow=${year}0902
fi    

gdnxt=${year}1001
#gdnxt=${newyear}0101

START=$(date -d "$gdnow" +"%Y-%m-%dT00:00:00")
END=$(date -d "$gdnxt" +"%Y-%m-%dT00:00:00")

echo $START
echo $END

# Hycom setups in common_ran.src

tsecnow=$(date -d "$gdnow" +%s)
tsecnxt=$(date -d "$gdnxt" +%s)
diff_sec=$((tsecnxt - tsecnow))
diff_day=$((diff_sec / 86400)) # restart file output frequency

meanfq=0         # archive file (average) dumping frequency [day]
rstrfq=$diff_day # restart file dumping frequency [day]

cat ./FILES/common_ran.src | \
    sed -e "s/^export MEANFQ=[0-9]\+/export MEANFQ=$meanfq/" \
        -e "s/^export RSTRFQ=[0-9]\+/export RSTRFQ=$rstrfq/" \
    > common_ran.src

# Submit job

bash submit_det_1cyc.sh $gdnow $gdnxt

#jid=$(bash submit_det_1cyc.sh $gdnow $gdnxt)
#echo $jid

exit $?
