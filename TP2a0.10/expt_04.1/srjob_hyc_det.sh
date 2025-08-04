#!/bin/bash

#SBATCH --account nn9481k      ## The billed account
#SBATCH --job-name=srun_sngl
#SBATCH --output log/srun_sngl_%A_%a.out  ## standard out
#SBATCH --error  log/srun_sngl_%A_%a.err  ## standard error 
#SBATCH --time=03:30:00
#SBATCH --nodes=4
##SBATCH --ntasks=504
#SBATCH --mail-type=END
#SBATCH --mail-user=tsuyoshi.wakamatsu@nersc.no

set -o errexit   ## Exit the script on any error
set -o nounset   ## Treat any unset variables as an error

START=$1
END=$2
Ncor=4

echo "Start time in pbsjob.sh: $START"
echo "End   time in pbsjob.sh: $END"

# ------------------- Fetch Environment ------------------------------

# Initialize environment (sets Scratch dir ($S), Data dir $D ++ )
source ../REGION.src || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src    || { echo "Could not source EXPT.src"; exit 1; }

# Enter SCRATCH dir and Run model
cd $S || { echo "Could not go to dir $S  "; exit 1; }

# Run HYCOM-CICE
srun --mpi=pmi2 -N $Ncor -n $NMPI --cpu_bind=cores ./hycom_cice 

exit $?

