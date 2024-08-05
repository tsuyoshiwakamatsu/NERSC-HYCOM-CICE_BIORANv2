#!/bin/bash

#SBATCH --account nn9481k      ## The billed account
#SBATCH --job-name=TP2a042
#SBATCH --output log/slurm-%j.out  ## Name of the output-script 
#SBATCH --error  log/slurm-%j.err  ## Name of the error-script 
                                   ## (%j will be replaced with job number)
#SBATCH --time=00:30:00
#SBATCH --nodes=4
#SBATCH --ntasks=504
#SBATCH --mail-type=END
#SBATCH --mail-user=tsuyoshi.wakamatsu@nersc.no

set -o errexit   ## Exit the script on any error
set -o nounset   ## Treat any unset variables as an error

export NMPI=504
echo "NMPI =$NMPI (Number of MPI tasks needed for running job) "

# ------------------- Fetch Environment ------------------------------

# Initialize environment (sets Scratch dir ($S), Data dir $D ++ )
source ../REGION.src  || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src  || { echo "Could not source EXPT.src"; exit 1; }

# Set integration period and INIFLG

START="2016-01-01T00:00:00"
END="2016-01-08T00:00:00"
INITFLG=""
echo "Start time in pbsjob.sh: $START"
echo "End   time in pbsjob.sh: $END"

mkdir -p log

# Generate atmospheric forcing :
atmo_synoptic.sh era5 $START $END ||{ echo "atmo_synoptic had fatal errors "; exit 1; }

# Transfer data files to SCRATCH
expt_preprocess.sh $START $END $INITFLG || { echo "Preprocess had fatal errors "; exit 1; }

# 
#cp ./hycom_fabm.nml $S
#cp ./fabm.yaml $S

# Enter SCRATCH dir and Run model
cd $S || { echo "Could not go to dir $S  "; exit 1; }

# Run HYCOM-CICE
srun -n $NMPI --cpu_bind=cores ./hycom_cice 

# Cleanup and move data files to data directory
cd $P || { echo "Could not go to dir $P  "; exit 1; }
expt_postprocess.sh 

exit $?

