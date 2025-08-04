#!/bin/bash

#SBATCH --account nn9481k      ## The billed account
#SBATCH --job-name=hyc_ens_array
#SBATCH --output log/hyc_ens_%A_%a.out  ## standard out
#SBATCH --error  log/hyc_ens_%A_%a.err  ## standard error 
#SBATCH --time=06:00:00
#SBATCH --nodes=4
##SBATCH --ntasks=504
#SBATCH --mail-type=END
#SBATCH --mail-user=tsuyoshi.wakamatsu@nersc.no

set -o errexit   ## Exit the script on any error
set -o nounset   ## Treat any unset variables as an error

#START=$1
#END=$2

Ncor=4   # number of nodes per single member

#echo "Start time in $0: $START"
#echo "End   time in $0: $END"

# ------------------- Fetch Environment ------------------------------

# Initialize environment (sets Scratch dir ($S), Data dir $D ++ )
source ../REGION.src || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src    || { echo "Could not source EXPT.src"; exit 1; }

# Ensemble member ID

imem=$SLURM_ARRAY_TASK_ID
Exdir=$S/mem$(printf "%03d" $imem)

# Enter SCRATCH dir and Run model
cd $Exdir/SCRATCH || { echo "Could not go to dir $Exdir/SCRATCH "; exit 1; }

# Run HYCOM-CICE
srun --mpi=pmi2 -N $Ncor -n $NMPI --cpu_bind=cores ./hycom_cice 

exit $?

