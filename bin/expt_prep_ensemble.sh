#!/bin/bash
set -xu

create_symlink() {
    local symlink="$1"
    local target_file="$2"
    ln -sf $target_file $symlink
    [ -L "$symlink" ] && [ ! -e "$symlink" ] && {
        echo "Error: The symlink '$symlink' is dead."
        exit 1
    }
}

export BASEDIR=$(cd .. && pwd)

START=$1
NENS=$2
INITENS_ATM=$3  # "--init"/"--clone"                      ## Atmospheric forcing
INITENS_RST=$4  # "--init"/"--clone"/"--copy"             ## Hycom restart
INITENS_ICE=$5  # "--init"/"--clone"/"--copy"             ## CICE restart. Only --clone option is available
INITENS_BGC=$6  # "--init"/"--clone"/"--copy"/"--perturb  ## FABM parameters

PERR_BGC_INIT=20 # [%] # error percentage of default value
PERR_BGC_PTRB=5  # [%] # error percentage of value range (max-min)

# Initialize environment (sets Scratch dir ($S), Data dir $D ++ )
if [ -f EXPT.src ] ; then
   export BASEDIR=$(cd .. && pwd)
else
   echo "Could not find EXPT.src. This script must be run in expt dir"
   exit 1
fi
source ../REGION.src || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src    || { echo "Could not source EXPT.src"; exit 1; }

# Recover restart file name headers

hour=$(date -d "$START" +%H)
minute=$(date -d "$START" +%M)
second=$(date -d "$START" +%S)

total_seconds=$((minute * 60 + second))
fhead_rst=restart.$(date -d "$START" +%Y_%j_%H)_$(printf "%04d" $total_seconds)

total_seconds=$((hour * 3600 + minute * 60 + second))
fhead_ice=iced.$(date -d "$START" +%Y-%m-%d)-$(printf "%05d" $total_seconds)

# Time stamp for parameter files

gdate=$(date -d "$START" +"%Y%m%d")

# Range of ensemble members ID

mem1=1
mem2=$(expr $NENS + $mem1 - 1)

#-----------------------------------
# rewrite default fabm.yaml based on Parameter_bio_mem000.txt 
#-----------------------------------

cd $S
for file in Parameter_bio*.txt; do
   [ -f $file ] && rm $file
done
$MSCPROGS/bin/init_param_bio 0 0 "NORM"
list=$S/Parameter_bio_mem000.txt

if [ -f $list ]; then
   cd $P
   if [ -f fabm.yaml ]; then
      while IFS=": " read -r param new_value; do
         sed -i "/$param: /s/\($param: \s*\).*/\1$new_value/" "fabm.yaml"
      done < "$list"
   else
      echo "fabm.yaml can not be found, STOP"; exit 1
   fi
else
   echo "$list can not be found, STOP"; exit 1
fi

#-----------------------------------
# Initialize ensemble exec folders (cloning SCRATCH)
#-----------------------------------

cd $P
for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem
   [ -d $Exdir ] && rm -rf $Exdir
   mkdir -p $Exdir/SCRATCH/cice
   cd $Exdir/SCRATCH
   for file in $P/SCRATCH/*; do
      [ ! -d $file ] && ln -sf $file .
   done
   cd $Exdir/SCRATCH/cice
   for file in $P/SCRATCH/cice/*; do
      [ ! -d $file ] && ln -sf $file .
   done
done

#-----------------------------------
# Ensemble atmospheric forcing
#-----------------------------------

if [ "$INITENS_ATM" == "--init" ]; then

# List of forcing variables for perturbation
#
# Full list: airtmp mslprs precip wndewd wndnwd nswrad radflx shwfl
Pervars="airtmp mslprs precip wndewd wndnwd nswrad radflx shwflx"
#Pervars="radflx shwflx"

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH
   create_symlink infile2.in $P/infile2.in
   $MSCPROGS/bin/force_perturb-2.2 era-i era40 > /dev/null 2>&1

   for file in tst.forcing.*.a; do
      pvar=$(echo $file | cut -d'.' -f3)
      if [[ " $Pervars " =~ " $pvar " ]]; then
         rm forcing.${pvar}.[ab]
         create_symlink forcing.${pvar}.a tst.forcing.${pvar}.a
         create_symlink forcing.${pvar}.b tst.forcing.${pvar}.b
      else
         rm tst.forcing.${pvar}.[ab]
      fi
   done
done

fi

#-----------------------------------
# Ensemble FABM parameter files
#-----------------------------------

if [ "$INITENS_BGC" == "--clone" ]; then # clone default fabm.yaml
   cd $S
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem)
      cp Parameter_bio_mem000.txt $D/Parameter_bio_mem${fmem}_${gdate}.txt
   done
elif [ "$INITENS_BGC" == "--init" ]; then # generate ensemble
   cd $S
   for file in Parameter_bio*.txt; do
      [ -f $file ] && rm $file
   done
   $MSCPROGS/bin/init_param_bio $NENS $PERR_BGC_INIT "NORM"
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem)
      cp Parameter_bio_mem${fmem}.txt $D/Parameter_bio_mem${fmem}_${gdate}.txt
   done
elif [ "$INITENS_BGC" == "--perturb" ]; then # reperturb existing ensemble
   cd $S
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem)
      cp $D/Parameter_bio_mem${fmem}_${gdate}.txt Parameter_bio_mem${fmem}.txt 
   done
   $MSCPROGS/bin/ptrb_param_bio $NENS $PERR_BGC_PTRB "NORM"
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem)
      cp Parameter_bio_mem${fmem}.txt $D/Parameter_bio_mem${fmem}_${gdate}.txt
   done
elif [ "$INITENS_BGC" == "--copy" ]; then # copy existing ensemble
   cd $D
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem)
      [ -f Parameter_bio_mem${fmem}_${gdate}.txt ] && echo "use Parameter_bio_mem${fmem}_${gdate}.txt"
   done
else
   echo "INITENS_BGC:$INITENS_BGC not supported, STOP"; exit
fi

# rewrite ensemble fabm.yaml based on $D/Parameter_bio_mem$fmem_$gdate.txt 
# and broadcast the ensemble fabm.yaml files to ensemble SCRATCH

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem
   cd $Exdir
   cp $P/fabm.yaml .
   list=$D/Parameter_bio_mem${fmem}_${gdate}.txt
   if [ -f $list ]; then
      while IFS=": " read -r param new_value; do
         sed -i "/$param: /s/\($param: \s*\).*/\1$new_value/" "fabm.yaml"
      done < "$list"
   else
      echo "$list can not be found, STOP"; exit
   fi
   create_symlink hycom_fabm.nml $P/hycom_fabm.nml
done

#-----------------------------------
# Generate ensemble hycom restart files
#-----------------------------------

cd $S
if [ "$INITENS_RST" == "--clone" ]; then
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem) # formatted ensemble member ID
      cp ${fhead_rst}.a $D/${fhead_rst}_mem${fmem}.a
      cp ${fhead_rst}.b $D/${fhead_rst}_mem${fmem}.b
   done
elif [ "$INITENS_RST" == "--init" ]; then
   if [ -s $P/gen_ens.in ]; then # ensemble perturbation setup file
      cat $P/gen_ens.in |
       sed -e "1s/.*/${fhead_rst}.a/g" \
           -e "2s/.*/${NENS}            # Total number of ensemble members to create/g" \
       > gen_ens.in
   else
      echo "Can not find gen_ens.int, STOP"; exit 1
   fi
   $MSCPROGS/bin/gen_ens
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem) # formatted ensemble member ID
      cp ${fhead_rst}_mem${fmem}.a $D
      cp ${fhead_rst}_mem${fmem}.b $D
   done
elif [ "$INITENS_RST" == "--copy" ]; then
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem) # formatted ensemble member ID
      [ -f $D/${fhead_rst}_mem${fmem}.a ] && echo "use ${fhead_rst}_mem${fmem}.a"
      [ -f $D/${fhead_rst}_mem${fmem}.b ] && echo "use ${fhead_rst}_mem${fmem}.b"
   done      
else
   echo "INITENS_RST:$INITENS_RST not supported, STOP"; exit 1
fi

# broadcast ensemble retart files to ensemble SCRATCH

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH
   for file in ${fhead_rst}*; do
      rm $file
   done
   create_symlink ${fhead_rst}.a $D/${fhead_rst}_mem${fmem}.a
   create_symlink ${fhead_rst}.b $D/${fhead_rst}_mem${fmem}.b
done

#-----------------------------------
# Ensemble cice restart files
#-----------------------------------

if [ "$INITENS_ICE" == "--clone" ]; then
   cd $S/cice
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem) # formatted ensemble member ID
      cp ${fhead_ice}.nc $D/cice/${fhead_ice}_mem${fmem}.nc
   done
elif [ "$INITENS_RST" == "--copy" ]; then
   cd $S/cice
   for imem in $(seq $mem1 $mem2); do
      fmem=$(printf "%03d" $imem) # formatted ensemble member ID
      [ -f $D/cice/${fhead_ice}_mem${fmem}.nc ] && echo "use ${fhead_ice}_mem${fmem}.nc"
   done
else
   echo "INITENS_ICE:$INITENS_ICE not supported, STOP"; exit 1
fi

# broadcast ensemble retart files to ensemble SCRATCH

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH/cice
   for file in ${fhead_ice}*; do
      rm $file
   done
   create_symlink ${fhead_ice}.nc $D/cice/${fhead_ice}_mem${fmem}.nc
done

#-----------------------------------
# Nesting files
#-----------------------------------

for imem in $(seq $mem1 $mem2); do
   fmem=$(printf "%03d" $imem) # formatted ensemble member ID
   Exdir=$S/mem$fmem

   cd $Exdir/SCRATCH
   [ -e nest ] && rm nest
   create_symlink nest $BASEDIR/nest/$E
done

exit 0
