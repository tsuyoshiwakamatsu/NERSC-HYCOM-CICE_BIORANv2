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

#gdnxt=${year}0904
gdnxt=${newyear}0101

START=$(date -d "$gdnow" +"%Y-%m-%dT00:00:00")
END=$(date -d "$gdnxt" +"%Y-%m-%dT00:00:00")

echo "START $START"
echo "END   $END"

# Ensemble run setups in common_ens.src

mem1=1
mem2=80
members=$(seq -s ',' $mem1 $mem2)
nens=$(( $(echo "$members" | grep -o ',' | wc -l) + 1 ))
#nens=$((mem2 - mem1 + 1))

echo "NENS  $nens"

initens_atm="--init"  # "--init"/"--clone"                     ## Atmospheric forcing
initens_rst="--init"  # "--init"/"--clone"/"--copy"            ## Hycom restart
initens_ice="--clone" # "--clone"/"--copy"                     ## CICE restart. Only --init option is not available
initens_bgc="--init"  # "--init"/"--clone"/"--copy"/"--perturb ## FABM parameters

[ -f common_ens.src ] && rm -rf common_ens.src
echo "export mem1=$mem1"                     >> common_ens.src
echo "export mem2=$mem2"                     >> common_ens.src
echo "export memmbers=$members"              >> common_ens.src
echo "export nens=$nens"                     >> common_ens.src
echo "export initens_atm=\"${initens_atm}\"" >> common_ens.src
echo "export initens_rst=\"${initens_rst}\"" >> common_ens.src
echo "export initens_ice=\"${initens_ice}\"" >> common_ens.src
echo "export initens_bgc=\"${initens_bgc}\"" >> common_ens.src

# Hycom setups in common_ran.src

tsecnow=$(date -d "$gdnow" +%s)
tsecnxt=$(date -d "$gdnxt" +%s)
diff_sec=$((tsecnxt - tsecnow))

rstrfq=$((diff_sec / 86400)) # restart file dumping frequency [day]
meanfq=0                     # archive file (average) dumping frequency [day]

cat ./FILES/common_ran.src | \
    sed -e "s/^export MEANFQ=[0-9]\+/export MEANFQ=$meanfq/" \
        -e "s/^export RSTRFQ=[0-9]\+/export RSTRFQ=$rstrfq/" \
    > common_ran.src

# Submit job

jid=$(bash submit_jid_init.sh); echo $jid
jid=$(bash submit_ens_1cyc_array.sh $gdnow $gdnxt $jid); echo $jid
echo $jid

exit $?
