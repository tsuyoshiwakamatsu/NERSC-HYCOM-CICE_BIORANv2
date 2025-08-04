#!/bin/bash

#SBATCH --account nn9481k           ## The billed account
#SBATCH --job-name=post_ens
#SBATCH --output log/post_ens_%A.out  ## standard out
#SBATCH --error  log/post_ens_%A.err  ## standard error
#SBATCH --time=05:00:00
#SBATCH --partition=preproc
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --mail-type=END
#SBATCH --mail-user=tsuyoshi.wakamatsu@nersc.no

set -o errexit   ## Exit the script on any error
set -o nounset   ## Treat any unset variables as an error

START=$1
END=$2

bash post_ens_array.sh $START $END

exit $?

