#!/bin/bash
#
# Pre
#
#
set -u

create_symlink() {
    local symlink="$1"
    local target_file="$2"
    ln -sf $target_file $symlink
    if [ -L "$symlink" ] && [ ! -e "$symlink" ]; then
        echo "Error: '$symlink' is a dead link."
        return 1
    else
        return 0
    fi
}

START=$1
END=$2

DATE_NOW=$(date -d "$START" +"%Y-%m-%d")
DATE_NXT=$(date -d "$END" +"%Y-%m-%d")
DATE_RST=$(date -d "$DATE_NOW" +"%Y_%j")
echo "DATE_NOW $DATE_NOW"
echo "DATE_NXT $DATE_NXT"
echo "DATE_RST $DATE_RST"

source common_ran.src
source ../REGION.src  || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src  || { echo "Could not source EXPT.src "; exit 1; }
export BASEDIR=$(dirname $P)

# Prepare restart files under $P/data

mkdir -p $D/cice


# Copy restart files from archive only when they can not be found under data
#if [ ! -f restart.${DATE_RST}_00_0000.a ]; then

# Copy restart files from archive only when they can be found under archive

if [ -f ${DIR_RST}/restart.${DATE_RST}_00_0000.a ]; then
   cd $D
   restart_afile=${DIR_RST}/restart.${DATE_RST}_00_0000.a
   restart_bfile=${DIR_RST}/restart.${DATE_RST}_00_0000.b
   create_symlink $(basename $restart_afile) $restart_afile
   create_symlink $(basename $restart_bfile) $restart_bfile
fi

if [ -f ${DIR_RST}/cice/iced.${DATE_NOW}-00000.nc ]; then
   cd $D/cice
   restart_icefile=${DIR_RST}/cice/iced.${DATE_NOW}-00000.nc
   create_symlink $(basename $restart_icefile) $restart_icefile
fi
#

# Prepare nesting files under $BASEDIR/nest
#
# notes:
#  1. maks sure that location of DIR_NST is visible from slrum
#  2. make sure date2doy is available under $BASEDIR/bin
#

cd $BASEDIR
[ -d nest/$E ] && rm -rf ./nest/$E
mkdir -p ./nest/$E

cd $BASEDIR/nest/$E

datenow=$(date -d "$START" +"%Y%m%d")
datenxt=$(date -d "$END" +"%Y%m%d")
ts_now=$(date -d "$START" +%s)
ts_nxt=$(date -d "$END" +%s)
diff_sec=$((ts_nxt - ts_now))
diff_day=$((diff_sec / 86400))

for jl in $(seq 0 ${diff_day}); do
   date=$(date -d "$datenow + $jl days" +"%Y%m%d")
   doy=$(date2doy $date)
   nest_afile=${DIR_NST}/archv.${date:0:4}_${doy}_00.a
   nest_bfile=${DIR_NST}/archv.${date:0:4}_${doy}_00.b
   create_symlink $(basename $nest_afile) $nest_afile
   create_symlink $(basename $nest_bfile) $nest_bfile
done

create_symlink ports.nest ${DIR_NST}/ports.nest
create_symlink rmu.a      ${DIR_NST}/rmu.a
create_symlink rmu.b      ${DIR_NST}/rmu.b
create_symlink rmutr.a    ${DIR_NST}/rmutr.a
create_symlink rmutr.b    ${DIR_NST}/rmutr.b

# additionl files for FABM

for jl in $(seq 0 ${diff_day}); do
   date=$(date -d "$datenow + $jl days" +"%Y%m%d")
   doy=$(date2doy $date)
   nest_fabm_afile=${DIR_NST}/archv_fabm.${date:0:4}_${doy}_00.a
   nest_fabm_bfile=${DIR_NST}/archv_fabm.${date:0:4}_${doy}_00.b
   create_symlink $(basename $nest_fabm_afile) $nest_fabm_afile
   create_symlink $(basename $nest_fabm_bfile) $nest_fabm_bfile
done

exit 0
