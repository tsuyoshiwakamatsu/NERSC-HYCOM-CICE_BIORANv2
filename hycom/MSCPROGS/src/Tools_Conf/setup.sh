#!/bin/bash
set -u

cnfg=$1

if [ -L get_topo.F90 ]; then
    rm get_topo.F90
fi

if [ -f get_topo_${cnfg}.F90 ]; then
    ln -sf get_topo_${cnfg}.F90 get_topo.F90
fi

exit
