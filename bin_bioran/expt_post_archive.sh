#!/bin/bash

NENS=2
KK=50
NTRACR=45
date='2016_155_12'

# Range of ensemble members ID

mem1=1
mem2=$(expr $NENS + $mem1 - 1)

# Initialize environment (sets Scratch dir ($S), Data dir $D ++ )
if [ -f EXPT.src ] ; then
   export BASEDIR=$(cd .. && pwd)
else
   echo "Could not find EXPT.src. This script must be run in expt dir"
   exit 1
fi
source ../REGION.src || { echo "Could not source ../REGION.src "; exit 1; }
source ./EXPT.src    || { echo "Could not source EXPT.src"; exit 1; }

TMPDIR=$P/data/TMP

[ -d $TMPDIR ] && rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR

filename="archm.$date"

[ -f list_files.txt ] && rm -rf list_files.txt
for imem in $(seq $mem1 $mem2); do
    fmem=$(printf "%03d" $imem) # formatted ensemble member ID
    afile=$D/$fmem/archm.$date.a
    [ -f $afile ] && ln -sf $afile file${fmem}.a
    bfile=$D/$fmem/archm.$date.b
    [ -f $bfile ] && ln -sf $bfile file${fmem}.b
    [ -f file${fmem}.a ] && echo file${fmem}.a >> list_files.txt
done  
ln -sf $D/regional* .

#-------------------------
# for BIORANv1
#-------------------------

cat list_files.txt

BINDIR=$MSCPROGS/bin

file_list=()
for file in file*.a; do
    file_list+=("$(basename "$file")")
done    

#[ -f AVE_9999_999_99.a ] && rm AVE_9999_999_99.a
#[ -f AVE_9999_999_99.b ] && rm AVE_9999_999_99.b

$BINDIR/hycave archm ${file_list[@]}

#[ -f AVE_9999_999_99.a ] && mv AVE_9999_999_99.a $filename.a
#[ -f AVE_9999_999_99.b ] && mv AVE_9999_999_99.b $filename.b

exit 0

#-------------------------
# for BIORANv2
#-------------------------

BINDIR=$HYCOM_ALL/meanstd/src_2.2.72

cat list_files.txt
sed -e "s/NN/${NENS}/g" -e "s/KK/${KK}/g" -e "s/NT/${NTRACR}/g" -e "s/FILENAME/${filename}/g" $P/mean_hycom.in |
    awk '/FILES/ {while ((getline line < "list_files.txt") > 0) print line; next} 1' > mean_hycom.in

$BINDIR/hycom_mean < mean_hycom.in
rm list_files.txt

exit 0

