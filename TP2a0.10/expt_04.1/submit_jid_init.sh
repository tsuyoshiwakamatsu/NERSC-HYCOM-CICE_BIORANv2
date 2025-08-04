#!/bin/bash
set -u

jid=$(sbatch srjob_jid_init.sh | sed 's/Submitted batch job //')
echo $jid

exit $?
