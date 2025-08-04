#!/bin/bash

#SBATCH --account nn9481k      ## The billed account
#SBATCH --job-name=hyc_ens
#SBATCH --output log/hyc_ens_%A.out  ## standard out
#SBATCH --error  log/hyc_ens_%A.err  ## standard error 
#SBATCH --time=24:00:00
#SBATCH --nodes=40
##SBATCH --ntasks=504
#SBATCH --mail-type=END
#SBATCH --mail-user=tsuyoshi.wakamatsu@nersc.no

set -o errexit   ## Exit the script on any error
set -o nounset   ## Treat any unset variables as an error

#START=$1
#END=$2

Nbatch=10 # Note: this number is designed by the whole cores and 
          #       it is better to be consistent with Ncore for each job run.
Ncor=4    # number of nodes per single member
Sleep=30

# ------------------- Fetch Environment ------------------------------

source common_ens.src || { echo "Could not source common_ens.src "; exit 1; }

# Initialize environment (sets Scratch dir ($S), Data dir $D ++ )
source ../REGION.src || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src    || { echo "Could not source EXPT.src"; exit 1; }

# submit ensemble jobs

pids=""
ncyc=$(expr \( $nens - 1 \) / $Nbatch + 1)

for icyc in $(seq 1 $ncyc); do
   i1=$(expr $mem1 + \( $icyc - 1 \) \* $Nbatch)
   i2=$(expr $i1 + $Nbatch - 1)
   if [ ${icyc} -eq ${ncyc} ]; then
      for imem in $(seq $i1 $i2); do
         Exdir=$S/mem$(printf "%03d" $imem) # ensemble SCRATCH folder
         cd $Exdir/SCRATCH || { echo "Could not go to dir $Exdir/SCRATCH  "; exit 1; } 
         if [ $imem -lt ${mem2} ]; then
            sleep $Sleep &
            pids="$pids $!"
            srun --mpi=pmi2 -N $Ncor -n $NMPI --cpu_bind=cores ./hycom_cice &
            pids="$pids $!"
            #echo $PWD
            #echo "$imem srun --mpi=pmi2 -N $Ncor -n $NMPI --cpu_bind=cores ./hycom_cice &"
         else
            sleep $Sleep &
            pids="$pids $!"
            srun --mpi=pmi2 -N $Ncor -n $NMPI --cpu_bind=cores ./hycom_cice
            pids="$pids $!"
            #echo $PWD
            #echo "$imem srun --mpi=pmi2 -N $Ncor -n $NMPI --cpu_bind=cores ./hycom_cice"
            break
         fi
      done
   else
      for imem in $(seq $i1 $i2); do
         Exdir=$S/mem$(printf "%03d" $imem) # ensemble SCRATCH folder
         cd $Exdir/SCRATCH || { echo "Could not go to dir $Exdir/SCRATCH  "; exit 1; } 
         sleep $Sleep &
         pids="$pids $!"
         srun --mpi=pmi2 -N $Ncor -n $NMPI --cpu_bind=cores ./hycom_cice &
         pids="$pids $!"
         #echo $PWD
         #echo "$imem srun --mpi=pmi2 -N $Ncor -n $NMPI --cpu_bind=cores ./hycom_cice &"
      done
      wait $pids
      #echo "wait"
   fi
done

exit $?

