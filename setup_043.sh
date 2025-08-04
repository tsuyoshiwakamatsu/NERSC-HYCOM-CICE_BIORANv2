#!/bin/bash
set -xu

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

export HYCOM_REPO=NERSC-HYCOM-CICE_BIORANv2

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

cd $HOME_HYCOM/${HYCOM_REPO}/hycom/MSCPROGS/src/Make.Inc

compiler=ifort # FORTRAN compiler (eg. gfortran, gnu)
hostname=$(head -n 1 /etc/motd | awk -F' ' '{split($3, parts, "."); print parts[1]}') # extract hostname from motd
echo $hostname
[ -L make.inc ] && rm make.inc
ln -sf make.$hostname.$compiler make.inc
ls -l make.inc

cd $HOME_HYCOM/${HYCOM_REPO}/hycom/MSCPROGS/src
#gmake clean
#gmake all
#gmake install

cd $HOME_HYCOM/${HYCOM_REPO}/hycom/hycom_ALL/hycom_2.2.72_ALL
compiler=intelIFC
if [ -f config/${compiler}_setup ]; then
   sed -i "/^setenv ARCH /c setenv ARCH $compiler" Make_all.src
else
   echo "Can not find setup file ${compiler}_setup, EXIT"
fi

#csh ./Make_clean.com
#csh ./Make_all.com
#csh ./Make_ncdf.com

cd $WORK_HYCOM
cp -r $HOME_HYCOM/${HYCOM_REPO}/$CONFIGNAME .
cd $WORK_HYCOM/$CONFIGNAME
[ -f bin ] && rm bin
ln -sf $HOME_HYCOM/${HYCOM_REPO}/bin .

cd $WORK_HYCOM/$CONFIGNAME
cp $HOME_HYCOM/${HYCOM_REPO}/input/REGION.src .
sed -i "/^export R=/c export R=$CONFIGNAME" REGION.src
sed -i "/^export NHCROOT=/c export NHCROOT=$HOME_HYCOM/${HYCOM_REPO}" REGION.src

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

cd $WORK_HYCOM/$CONFIGNAME/expt_$NEWEXPERIMENT
cp $HOME_HYCOM/${HYCOM_REPO}/bin/create_ref_case.sh .
ICORE=29    # number of tiles in i directrion
JCORE=26    # number of tiles in j directrion
sed -i "/^Icore=/c Icore=$ICORE" create_ref_case.sh
sed -i "/^Jcore=/c Jcore=$JCORE" create_ref_case.sh
sed -i "/^iceclim=/c iceclim=$ICECLIM" create_ref_case.sh

bash create_ref_case.sh


