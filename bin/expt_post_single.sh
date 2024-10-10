#!/bin/bash
#######################################################################
# Start post-processing
set -xue
trap 'abort' ERR

START=$1
END=$2

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

# Recover restart file name headers

hour=$(date -d "$END" +%H)
minute=$(date -d "$END" +%M)
second=$(date -d "$END" +%S)

total_seconds=$((minute * 60 + second))
fhead_rst=${restarto}.$(date -d "$END" +%Y_%j_%H)_$(printf "%04d" $total_seconds)

total_seconds=$((hour * 3600 + minute * 60 + second))
fhead_ice=iced.$(date -d "$END" +%Y-%m-%d)-$(printf "%05d" $total_seconds)

# Time stamp for parameter files

gdate=$(date -d "$END" +"%Y%m%d")

#-- delete ESMF log files (TODO: add option not to damp this log files in HYCOM-CICE)

cd $S
for file in PET*.ESMF_LogFile; do
    [ -f  $file ] && rm $file
done

#-- Save restart files to $D

cd $S
for i in ${fhead_rst}.* ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to $D"
     mv $i $D
  fi
done

#-- Save archive files to $D

cd $S
for i in $( ls ${nmarcv}*.[ab] ${nmarcs}*.[ab] ${nmarcm}*.[ab] ); do
  if [ -L "${i}" ]; then
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to  $D"
     mv $i $D
  fi
done

#-- Save CICE restart files to $D

cd $S/cice
for i in ${fhead_ice}*.nc ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to $D/cice"
     mv $i $D/cice
  fi
done

#-- Save CICE archive files 

cd $S/cice
for i in iceh*.nc ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to $D/cice"
     mv $i $D/cice
  fi
done

#-- Save some files useful for analysis

cd $S
for i in $( ls regional.* blkdat.input ice_in ); do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to $D"
     mv $i $D
  fi
done

#-- Save ECOSMO/FABM parameter files

cd $S
for i in Parameter_bio_* ; do
  if [ -L "${i}" ]; then #Delete link first to avoid recursive links
     echo "$i is a sympolic link, I am removing it"
     rm $i
  elif [ -f "$i" ] && [ ! -L "$i" ]; then
     echo "Moving $i to $D"
     mv $i $D
  fi
done

cd $P
[ -f fabm.yaml ] && cp fabm.yaml $D
[ -f hycom_fabm.nml ] && cp hycom_fabm.nml $D

#--  

cd $S
[ -f summary.out ] && cp summary_out $D

# --- HYCOM error stop is implied by the absence of a normal stop.

cd $S
if  [ `tail -1 summary_out | grep -c "^normal stop"` == 0 ] ; then
  cd $P
  echo "BADRUN"  > log/hycom.stop
else
  cd $P
  echo "GOODRUN" > log/hycom.stop
fi
