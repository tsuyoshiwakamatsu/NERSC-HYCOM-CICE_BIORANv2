#!/bin/bash

#SBATCH --account nn9481k           ## The billed account
#SBATCH --job-name=jid_init
#SBATCH --output log/jid_init_%A.out  ## standard out
#SBATCH --error  log/jid_init_%A.err  ## standard error
#SBATCH --time=00:30:00
#SBATCH --partition=preproc
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --mail-type=END
#SBATCH --mail-user=tsuyoshi.wakamatsu@nersc.no

set -o errexit   ## Exit the script on any error
set -o nounset   ## Treat any unset variables as an error

sleep 1

exit $?

