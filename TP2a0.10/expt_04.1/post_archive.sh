#!/bin/bash
set -u

date='2016_028_12'
filename="archm.$date"

source common_ens.src

mem1=1
mem2=2
nens=2

source ../REGION.src || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src    || { echo "Could not source EXPT.src"; exit 1; }

cd $D/SCRATCH

#BINDIR=$HYCOM_ALL/meanens/src
#BINDIR=$HYCOM_ALL/meanstd/src
BINDIR=$MSCPROGS/src/Ensmean

[ -f ${filename}.a ] && rm -rf ${filename}.a
[ -f ${filename}.b ] && rm -rf ${filename}.b

[ -f list_files.txt ] && rm -rf list_files.txt

for imem in $(seq $mem1 $mem2); do
    fmem=$(printf "%03d" $imem) # formatted ensemble member ID
    afile=./${filename}_mem$fmem.a
    [ -f $afile ] && echo $afile >> list_files.txt
    bfile=./${filename}_mem$fmem.b
done  

ln -sf $D/regional* .

cat list_files.txt

[ -f mean_hycom.in ] && rm mean_hycom.in

sed -e "s/NN/${nens}/g" \
    -e "s/FILENAME/${filename}/g" \
    $P/FILES/mean_hycom.in |
    awk '/FILES/ {while ((getline line < "list_files.txt") > 0) print line; next} 1' > mean_hycom.in

#$BINDIR/hycom_mean < mean_hycom.in
$BINDIR/ensmean

exit $?
