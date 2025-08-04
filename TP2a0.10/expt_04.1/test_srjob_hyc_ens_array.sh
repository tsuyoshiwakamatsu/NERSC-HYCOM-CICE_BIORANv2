#!/bin/bash
set -u

sbatch --array=1-80 srjob_hyc_ens_array.sh

exit $?
