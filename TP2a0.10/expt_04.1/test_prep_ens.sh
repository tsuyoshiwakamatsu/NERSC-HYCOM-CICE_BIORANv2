#!/bin/bash
set -u

# Set integration period

gdnow=20160318
gdnxt=20160325

START=$(date -d "$gdnow" +"%Y-%m-%dT00:00:00")
END=$(date -d "$gdnxt" +"%Y-%m-%dT00:00:00")

echo $START
echo $END

bash prep_ens.sh $START $END

exit $?
