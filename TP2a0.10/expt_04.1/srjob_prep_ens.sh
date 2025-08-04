#!/bin/bash

#SBATCH --account nn9481k           ## The billed account
#SBATCH --job-name=prep_ens
#SBATCH --output log/prep_ens-%A.out  ## standard out
#SBATCH --error  log/prep_ens-%A.err  ## standard error
#SBATCH --time=5:00:00
#SBATCH --partition=preproc
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --mail-type=END
#SBATCH --mail-user=tsuyoshi.wakamatsu@nersc.no

set -o errexit   ## Exit the script on any error
set -o nounset   ## Treat any unset variables as an error

START=$1
END=$2

bash prep_ens.sh $START $END

exit $?
