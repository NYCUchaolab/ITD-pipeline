#!/bin/sh

set -euo pipefail

# Global Variable
BASHRC=~/.bashrc

shopt -s expand_aliases
# source $BASHRC
source $ITD_PIPELINE_CONFIG
source $BANNER_SH
source $TOOLS

eval "$(conda shell.bash hook)"
VERSION=0.0.1
VERBOSE=0
PREFIX=./
SAMPLE_ID=SAMPLE
OUT_DIR=./


usage(){
>&2 cat << EOF
Usage: $0
  [ -V | --version ]
  [ -v | --verbose args; default=0 ]
  [ -h | --help ]
  [ -i | --input_dir args; default=./]
  [ -S | --sample_id args; default=SAMPLE ]
  [ -t | --tumor args ]
  [ -n | --normal args 
  [ -o | --out_dir args; default=./ ]
  [ -p | --partition args ]
EOF
} 

args=$(getopt -a -o Vv:hi:S:t:n:o:p: --long version,verbose:,help,input_dir:,sample_id:,tumor:,normal:,out_dir:,partition: -- "$@")

if [[ $? -gt 0 ]]; then
  usage
  exit 1
fi

eval set -- ${args}
while :
do
  case $1 in
    -V | --version)        echo $VERSION ; exit 1;;
    -v | --verbose)        VERBOSE=$2 ; shift 2;;
    -h | --help)           usage ; exit 1;;
    -i | --input_dir)      PREFIX=$2 ; shift 2;;
    -S | --sample_id)      SAMPLE_ID=$2 ; shift 2;;
    -t | --tumor)          TUMOR_FILEID=$2 ; shift 2;;
    -n | --normal)         NORMAL_FILEID=$2 ; shift 2;;
    -o | --out_dir)        OUT_DIR=$2   ; shift 2;;
    -p | --partition)      PARTITION=$2; shift 2;;

    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break;;

    *) >&2 echo Unsupported option: $1
       usage 
       exit 1;;
  esac
done

check_essential_option "input_dir" $PREFIX
check_essential_option "tumor" $TUMOR_FILEID
check_essential_option "normal" $NORMAL_FILEID
check_essential_option "partition" $PARTITION

log 1 "Version          : ${VERSION}"
log 1 "Sample Directory : ${PREFIX}"
log 1 "Output Directory : ${OUT_DIR}"
log 1 "Sample Case ID   : ${SAMPLE_ID}"
log 1 "Tumor File ID    : ${TUMOR_FILEID}"
log 1 "Normal File ID   : ${NORMAL_FILEID}"
log 1 "Partition Name   : ${PARTITION}"
log 1 ""

# FIXME: more robust script for none sliced BAM

TUMOR_PART_BAM=$PREFIX/$TUMOR_FILEID/$TUMOR_FILEID.$PARTITION.bam
NORMAL_PART_BAM=$PREFIX/$NORMAL_FILEID/$NORMAL_FILEID.$PARTITION.bam
CONFIG_FILE=$OUT_DIR/${TUMOR_FILEID}_${NORMAL_FILEID}.${PARTITION}.bam_config.txt

log 1 "Creating ${CONFIG_FILE}..."
touch $CONFIG_FILE
echo -e "${NORMAL_PART_BAM}\t${PINDEL_LENGTH}\t${SAMPLE_ID}_N" > $CONFIG_FILE
echo -e "${TUMOR_PART_BAM}\t${PINDEL_LENGTH}\t${SAMPLE_ID}_T" >> $CONFIG_FILE
log 1 "Successly created ${CONFIG_FILE}"
log 1

# log 1 "Finished make configuration file for T:${TUMOR_FILEID}\tN:${NORMAL_FILEID} pairs!"
# log 1 ""



