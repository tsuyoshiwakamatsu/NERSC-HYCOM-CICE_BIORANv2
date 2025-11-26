#!/bin/bash
#set -x

DATE_START=$1
DATE_END=$2
DIR_RST=$3
START=${DATE_START}"T00:00:00"
END=${DATE_END}"T00:00:00"

export CONFIGNAME="TP2a0.10"   # configuration name 
export NEWEXPERIMENT=04.2      # new experiment number
export T="04"                  # topography version number
export COMPILE_BIOMODEL="yes"  # turn on/off ("yes/no") BGC (FABM-ECOSMO) module
export MXBLCKS=9               # maximal number of ice blocks relates to MPI cores distribution
export ICECLIM=0               # prepare initial ice file from climatology (1) or not (otherwise)
export INITFLAG=""             # start physics from climatology "--init" or from restart ""
export NTRACR=1                # BGC on/off: 0-physics only; 1-biology restart; -1-biology initialized with climatology
export RSTRFQ=7                # restart file dumping frequency [day]
export RELAX=0                 # physics relaxation: 0-relaxation off; 1-relaxation on
export TRCRLX=1                # BGC relaxation: 0-relaxation off; 1-relaxation on
export LBFLAG=2                # lateral barotropic bndy flag (0=none, 1=port, 2=input) (default:0)
export BNSTFQ=1                # number of days between baro nesting archive input (default:0)
export NESTFQ=1                # number of days between 3-d  nesting archive input (default:0)

export NMPI=504

export HYCOM_REPO=NERSC-HYCOM-CICE_BIORANv2                      # HYCOM-CICE repository name

export USERNAME=$(whoami)                                        # your username
export SHRTNAME="$(echo "$CONFIGNAME" | sed -E 's/[a-z].*$//')"  # eg. TP2a0.10 > TP2
export HOME_HYCOM=/cluster/home/${USERNAME}/${SHRTNAME}          # HYCOM-CICE home directory
export HOME_FABM=/cluster/home/${USERNAME}/FABM                  # FABM(ECOSMO) home directory
export WORK_HYCOM=/cluster/work/users/${USERNAME}/${SHRTNAME}    # HYCOM-CICE work directory
export LIB_PYTHON=$HOME_HYCOM/$HYCOM_REPO/pythonlibs        # NERSC hycom python libraries directory
export PATH="$HOME_HYCOM/$HYCOM_REPO/bin:$PATH"             # MSCPROGS bin diectory
#export IEXPT=$(expr 10 \* $(printf "%.0f" $NEWEXPERIMENT) | xargs printf "%03d") # eg. "03.0" > "030"
export IEXPT=$(echo "$NEWEXPERIMENT" | sed 's/\.//') # eg. "03.0" > "030"

mkdir -p $HOME_HYCOM
mkdir -p $HOME_FABM 
mkdir -p $WORK_HYCOM

cd $WORK_HYCOM
cp -r $HOME_HYCOM/${HYCOM_REPO}/$CONFIGNAME .
cd $WORK_HYCOM/$CONFIGNAME
[ -f bin ] && rm bin
ln -sf $HOME_HYCOM/${HYCOM_REPO}/bin .

cd $WORK_HYCOM/$CONFIGNAME
cp $HOME_HYCOM/${HYCOM_REPO}/input/REGION.src .
sed -i "/^export R=/c export R=$CONFIGNAME" REGION.src
sed -i "/^export NHCROOT=/c export NHCROOT=$HOME_HYCOM/${HYCOM_REPO}" REGION.src

cd $WORK_HYCOM/$CONFIGNAME
bin/expt_new.sh 01.0 $NEWEXPERIMENT

cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT
if [ -f blkdat.input_expt04.2 ]; then
   cp blkdat.input_expt04.2 blkdat.input
else
   cp /cluster/projects/nn9481k/shuang/Files_cp_other/blkdat.input_expt04.2 blkdat.input
fi
filename='blkdat.input'
# Define a dictionary (an associative array) of keyword and replacement.
# Note length of keyword inside of a bracket [""] is fixed to 6 including blanks.
declare -A replacements=( 
    ["iexpt "]="$IEXPT"  # experiment number
    ["relax "]="$RELAX"  # physics relaxation: 0-relaxation off; 1-relaxation on
    ["ntracr"]="$NTRACR" # BGC on/off: 0-physics only; 1-biology restart; -1-biology initialized with climatology
    ["trcrlx"]="$TRCRLX" # BGC relaxation: 0-relaxation off; 1-relaxation on
    ["rstrfq"]="$RSTRFQ" # frequency of model restart dump [day] Note: Only integer. Do not use float
    ["lbflag"]="$LBFLAG" # lateral barotropic bndy flag (0=none, 1=port, 2=input)
    ["bnstfq"]="$BNSTFQ" # number of days between baro nesting archive input
    ["nestfq"]="$NESTFQ" # number of days between 3-d  nesting archive input
 )

tempfile=$(mktemp)
while IFS= read -r line; do
    for keyword in "${!replacements[@]}"; do
        replacement="${replacements[$keyword]}"
        if [[ "$line" == *"$keyword"* ]]; then
            line=$(echo "$line" | sed -E "s/^([[:space:]]*)(-?[0-9]+)/\1$replacement/")
            break
        fi
    done
    echo "$line" >> "$tempfile"
done < "$filename"
mv "$tempfile" "$filename"

cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT
#echo ""                                                >> EXPT.src
#echo "# add new parameters for FABM and ICE"           >> EXPT.src
#echo "export MXBLCKS=${MXBLCKS}"                       >> EXPT.src # maximal number of ice blocks 
#echo "export COMPILE_BIOMODEL=\"${COMPILE_BIOMODEL}\"" >> EXPT.src # FABM coupler ON ("yes") or OFF ("no")
sed -i "/^T=/c T=\"$T\"" EXPT.src                                  # topography version
sed -i "/^export NMPI=/c export NMPI=$NMPI" EXPT.src
sed -i "/^export MXBLCKS=/c export MXBLCKS=$MXBLCKS" EXPT.src
sed -i "/^export COMPILE_BIOMODEL=/c export COMPILE_BIOMODEL=\"${COMPILE_BIOMODEL}\"" EXPT.src

#DIR_RST=/nird/datalake/NS9481K/shuang/TP2_output/expt_04.3

cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT/
[ -d data ] && rm -rf data
mkdir -p data/cice
#
#DIR_RST=/nird/datalake/NS9481K/shuang/TP2_output/expt_04.2  # 1993-2015
DATE_RESTART=$(date -d "$DATE_START" +%Y_%j)
#
DSTDIR=$WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT/data
cd $DSTDIR
restart_afile=${DIR_RST}/restart.${DATE_RESTART}_00_0000.a
restart_bfile=${DIR_RST}/restart.${DATE_RESTART}_00_0000.b

for file_restart in $restart_afile $restart_bfile; do
    if [ -f $file_restart ]; then
	file=$DSTDIR/$(basename $file_restart)
	if [ -f $file ]; then
	    echo "$file exists already, SKIP"
	else
	    echo "Copy to $file"
	    cp $file_restart .
	fi
    else
	echo "Can not find $file_restart, EXIT"
	exit
    fi
done

#
DSTDIR=$WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT/data/cice
cd $DSTDIR
restart_icefile=${DIR_RST}/cice/iced.${DATE_START}-00000.nc

if [ -f $restart_icefile ]; then
    file=$DSTDIR/$(basename $restart_icefile)
    if [ -f $file ]; then
	echo "$file exists already, SKIP"
    else
	echo "Copy to $file"
	cp $restart_icefile .
    fi
else
    echo "Can not find $restart_icefile, EXIT"
    exit
fi

#DIR_NST=/nird/datalake/NS9481K/shuang/nest/TP2_expt042
DIR_NST=/nird/datalake/NS9481K/shuang/nest/TP2_expt043

cd $WORK_HYCOM/$CONFIGNAME
[ -d nest/$IEXPT ] && rm -rf ./nest/$IEXPT
mkdir -p ./nest/$IEXPT

DSTDIR=$WORK_HYCOM/$CONFIGNAME/nest/$IEXPT
cd $DSTDIR
#
# works only when start and end dates belong to the same year (yy).
NDOY=$(( ( $(date -d "$DATE_END" +%s) - $(date -d "$DATE_START" +%s) ) / 86400 ))
DOY_START=$(date -d "$DATE_START" +%j)
DOY_END=$((DOY_START + NDOY))
YYYY_START=$(date -d "$DATE_START" +%Y)
echo ${DOY_START}-${DOY_END}

for dn in `seq -w ${DOY_START} ${DOY_END}`; do
    gdate=$(date -d "${YYYY_START}-01-01 +${dn} days -1 day" +"%Y-%m-%d")
    year=$(date -d "$gdate" +%Y)
    doy=$(date -d "$gdate" +%j)
    nst_afile=${DIR_NST}/archv.${year}_${doy}_00.a
    nst_bfile=${DIR_NST}/archv.${year}_${doy}_00.b
    nst_fabm_afile=${DIR_NST}/archv_fabm.${year}_${doy}_00.a
    nst_fabm_bfile=${DIR_NST}/archv_fabm.${year}_${doy}_00.b

    for file_archv in $nst_afile $nst_bfile $nst_fabm_afile $nst_fabm_bfile; do
        if [ -f $file_archv ]; then
	    file=$DSTDIR/$(basename $file_archv)
	    if [ -f $file ]; then
		echo "$file exists alreadyR, SKIP"
	    else
		echo "Copy to $file"
	        cp $file_archv .
	    fi
	else
	    echo "Can not find $file_archv, EXIT"
	    exit
        fi
    done
done

cp ${DIR_NST}/ports.nest .
cp ${DIR_NST}/rmu.a .
cp ${DIR_NST}/rmu.b .
cp ${DIR_NST}/rmutr.a .
cp ${DIR_NST}/rmutr.b .

ERA5=/cluster/projects/nn9481k/ERA5_6h

if [ -d $ERA5 ]; then
    cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT
    atmo_synoptic.sh era5 $START $END
else
    echo "Can not find $ERA5, EXIT"
    exit
fi    

cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT
expt_preprocess.sh $START $END $INITFLAG
