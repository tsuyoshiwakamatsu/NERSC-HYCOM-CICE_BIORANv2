#!/bin/bash

set -u

START=$1
END=$2

DATE_NOW=$(date -d "$START" +"%Y-%m-%d")
DATE_NXT=$(date -d "$END" +"%Y-%m-%d")

source ran_common_rst.src

# Prepare restart files

cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT/
#[ -d data ] && rm -rf data
mkdir -p data/cice
#
DATE_RESTART=$(date -d "$DATE_NOW" +%Y_%j)
#
cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT/data

# Copy restart files from archive only when they can not be found under data

if [ ! -f restart.${DATE_RESTART}_00_0000.a ]; then
   restart_afile=${DIR_RST}/restart.${DATE_RESTART}_00_0000.a
   restart_bfile=${DIR_RST}/restart.${DATE_RESTART}_00_0000.b
   [ -f "$restart_afile" ] && cp $restart_afile .
   [ -f "$restart_bfile" ] && cp $restart_bfile .

   cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT/data/cice
   restart_icefile=${DIR_RST}/cice/iced.${DATE_NOW}-00000.nc
   [ -f "$restart_icefile" ] && cp ${restart_icefile} . 
fi
#

# Prepare nesting files

cd $WORK_HYCOM/$CONFIGNAME
[ -d nest/$IEXPT ] && rm -rf ./nest/$IEXPT
mkdir -p ./nest/$IEXPT
#
#DIR_NST=/nird/datalake/NS9481K/shuang/nest/TP2_expt042
# works only when start and end dates belong to the same year (yy).
DOY_NOW=$(date -d "$DATE_NOW" +%j)
DOY_NXT=$(date -d "$DATE_NXT" +%j)
yy=$(date -d "$DATE_NOW" +%Y)
#echo $DOY_NOW-$DOY_NXT
#
cd $WORK_HYCOM/$CONFIGNAME/nest/$IEXPT
for dn in `seq -w ${DOY_NOW} ${DOY_NXT}`; do
   cp ${DIR_NST}/archv.${yy}_${dn}_00.a . || { echo "Could not get archv.${yy}_${dn}_00.a file " ; exit 1 ; }
   cp ${DIR_NST}/archv.${yy}_${dn}_00.b . || { echo "Could not get archv.${yy}_${dn}_00.b file " ; exit 1 ; }
   cp ${DIR_NST}/archv_fabm.${yy}_${dn}_00.a . || { echo "Could not get archv_fabm.${yy}_${dn}_00.a file " ; exit 1 ; }
   cp ${DIR_NST}/archv_fabm.${yy}_${dn}_00.b . || { echo "Could not get archv_fabm.${yy}_${dn}_00.b file " ; exit 1 ; }
done
cp ${DIR_NST}/ports.nest . || { echo "ports.nest " ; exit 1 ; }
cp ${DIR_NST}/rmu.a . || { echo "rmu.a " ; exit 1 ; }
cp ${DIR_NST}/rmu.b . || { echo "rmu.b " ; exit 1 ; }
cp ${DIR_NST}/rmutr.a . || { echo "rmutr.a " ; exit 1 ; }
cp ${DIR_NST}/rmutr.b . || { echo "rmutr.b " ; exit 1 ; }
