#!/bin/bash
#######################################################################
# Start post-processing
set -xue
trap 'abort' ERR

START=$1
END=$2
NENS=$3
INITENS_RST=$4
INITENS_ICE=$5
INITENS_BGC=$6

# Range of ensemble members ID

mem1=1
mem2=$(expr $NENS + $mem1 - 1)

# Must be in expt dir to run this script
if [ -f EXPT.src ] ; then
   export BASEDIR=$(cd .. && pwd)
else
   echo "Could not find EXPT.src. This script must be run in expt dir"
   exit 1
fi
export BINDIR=$(cd $(dirname $0) && pwd)/
if [ -z ${BASEDIR} ] ; then
   tellerror "BASEDIR Environment not set "
   exit
fi

# Initialize environment (sets Scratch dir ($S), Data dir $D ++ ) - must be in
# experiment dir for this to work
source ../REGION.src  || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src  || { echo "Could not source EXPT.src "; exit 1; }
source $BINDIR/common_functions.sh  || { echo "Could not source common_functions.sh "; exit 1; }

[ ! -d $D ] && mkdir $D
[ ! -d $D/cice ] && mkdir $D/cice

# Print error if we cannot descend scratch dir $S
cd $S || { cd $P ; echo "BADRUN" > log/hycom.stop ;  exit 1 ;}

touch   PIPE_DEBUG
/bin/rm PIPE_DEBUG

# Get names of archive files, restart files, etc
restarto=$(blkdat_get_string blkdat.input nmrsto "restart_out")
nmarcv=$(blkdat_get_string blkdat.input nmarcv "archv.")
nmarcs=$(blkdat_get_string blkdat.input nmarcs "archs.")
nmarcm=$(blkdat_get_string blkdat.input nmarcm "archm.")

# Recover restart file name headers at the end

hour=$(date -d "$END" +%H)
minute=$(date -d "$END" +%M)
second=$(date -d "$END" +%S)

total_seconds=$((minute * 60 + second))
fhead_rst=${restarto}.$(date -d "$END" +%Y_%j_%H)_$(printf "%04d" $total_seconds)

total_seconds=$((hour * 3600 + minute * 60 + second))
fhead_ice=iced.$(date -d "$END" +%Y-%m-%d)-$(printf "%05d" $total_seconds)

# Recover restart file name headers at the start

hour=$(date -d "$START" +%H)
minute=$(date -d "$START" +%M)
second=$(date -d "$START" +%S)

total_seconds=$((minute * 60 + second))
fhead_rst_init=${restarto}.$(date -d "$START" +%Y_%j_%H)_$(printf "%04d" $total_seconds)

total_seconds=$((hour * 3600 + minute * 60 + second))
fhead_ice_init=iced.$(date -d "$START" +%Y-%m-%d)-$(printf "%05d" $total_seconds)

# Time stamp for initial ensemble members and parameter files

gdnxt=$(date -d "$END" +"%Y%m%d")

#-- delete ESMF log files (TODO: add option not to damp this log files in HYCOM-CICE)

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem
   cd $Exdir/SCRATCH
   for file in PET*.ESMF_LogFile; do
      [ -f  $file ] && rm $file
   done
done

#-- Save ensemble restart files to $D after tagged with $fmem

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH

for i in ${fhead_rst}.* ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     file=${i%.*}_mem${fmem}.${i##*.}
     echo "Moving $file to $D"
     mv $i $D/$file
  fi
done

if [ "$INITENS_RST" == "--init" ] || [ "$INITENS_RST" == "--clone" ]; then

for i in ${fhead_rst_init}.* ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     file=${i%.*}_mem${fmem}.${i##*.}
     echo "Moving $file to $D"
     mv $i $D/$file
  fi
done

fi

done

#-- Save ensemble archive files to $D/$fmem for averaging

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH
   mkdir -p $D/$fmem 

for i in $( ls ${nmarcv}*.[ab] ${nmarcs}*.[ab] ${nmarcm}*.[ab] ); do
  if [ -L "${i}" ]; then
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to  $D"
     mv $i $D/$fmem 
  fi
done

done

#-- Save ensemble CICE restart files to $D/cice after tagged with $fmem

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH/cice

for i in ${fhead_ice}*.nc ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     file=${i%.*}_mem${fmem}.${i##*.}
     echo "Moving $file to $D/cice"
     mv $i $D/cice/$file
  fi
done

if [ "$INITENS_ICE" == "--init" ] || [ "$INITENS_ICE" == "--clone" ]; then

for i in ${fhead_ice_init}*.nc ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     file=${i%.*}_mem${fmem}.${i##*.}
     echo "Moving $file to $D/cice"
     mv $i $D/cice/$file
  fi
done

fi

done

#-- Save ensemble CICE archive files to $D/cice/$imem for averaging 

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH/cice
   mkdir -p $D/cice/$fmem

for i in iceh*.nc ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to $D/cice"
     mv $i $D/cice/$fmem
  fi
done

done

#-- Save some files useful for analysis

cd $S

for i in $( ls regional.* blkdat.input ); do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to $D"
     mv $i $D
  fi
done

#-- Save ECOSMO/FABM ensemble parameter files after tagged with $gdnxt

cd $S

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH

for i in Parameter_* ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     file=${i%.*}_${gdnxt}.${i##*.}
     echo "Moving $file to $D"
     if [ "$INITENS_BGC" == "--init" ] || [ "$INITENS_BGC" == "--clone" ]; then
        file=${i%.*}_${gdnow}.${i##*.}
        echo "Moving $file to $D"
        cp $i $D/$file
     fi
     mv $i $D/$file
  fi
done

done

# --- HYCOM error stop is implied by the absence of a normal stop.

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH
   #[ -f summary.out ] && cp summary_out_$fmem $D #-- Not sure what to do with this now 

if  [ `tail -1 summary_out | grep -c "^normal stop"` == 0 ] ; then
  echo "BADRUN"  > $P/log/hycom_mem$fmem.stop
else
  echo "GOODRUN" > $P/log/hycom_mem$fmem.stop
fi

done
