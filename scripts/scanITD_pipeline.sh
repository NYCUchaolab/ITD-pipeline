#!/bin/sh

set -euo pipefail

# Global Variable
BASHRC=~/.bashrc

shopt -s expand_aliases
# source $BASHRC
source $ITD_PIPELINE_CONFIG
source $BANNER_SH
source $TOOLS

VERSION=0.1.1
VERBOSE=0
SAMPLE_ID=SAMPLE
OUT_DIR=./

eval "$(conda shell.bash hook)"

usage(){
>&2 cat << EOF
Usage: $0
  [ -V | --version ]
  [ -v | --verbose args; default=0 ]
  [ -h | --help ]
  [ -S | --sample_id args; default=SAMPLE ]
  [ -t | --tumor args ]
  [ -n | --normal args ]
  [ -o | --out_dir args; default=./ ]
EOF
}

args=$(getopt -a -o Vv:hs:t:n:o: --long version,verbose:,help,sample_id:,tumor:,normal:,out_dir: -- "$@")

if [[ $? -gt 0 ]]; then
  usage
  exit 1
fi

eval set -- ${args}
while :
do
  case $1 in
    -V | --version)        echo $VERSION ; exit 1 ;;
    -v | --verbose)        VERBOSE=$2 ; shift 2 ;;
    -h | --help)           usage ; exit 1 ;;
    -s | --sample_id)      SAMPLE_ID=$2 ; shift 2;;
    -t | --tumor)          TUMOR_SAMPLE=$2 ; shift 2;;
    -n | --normal)         NORMAL_SAMPLE=$2 ; shift 2;;
    -o | --out_dir)        OUT_DIR=$2   ; shift 2 ;;

    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    *) >&2 echo Unsupported option: $1
       usage 
       exit 1;;
  esac
done

log 1 "Version          : ${VERSION}"
log 1 "Sample Case ID   : ${SAMPLE_ID}"
log 1 "Tumor Sample     : ${TUMOR_SAMPLE}"
log 1 "Normal Sample    : ${NORMAL_SAMPLE}"
log 1 "Output Directory : ${OUT_DIR}"
log 1 ""

# sliced BAM file location
TUMOR_ID=$(basename "$TUMOR_SAMPLE" .bam)
NORMAL_ID=$(basename "$NORMAL_SAMPLE" .bam)

TUMOR_DIR=${OUT_DIR}/${TUMOR_ID}
NORMAL_DIR=${OUT_DIR}/${NORMAL_ID}

check_and_create_dir ${OUT_DIR} ${TUMOR_ID}
log 1 ""

check_and_create_dir ${OUT_DIR} ${NORMAL_ID}
log 1 ""

SAMPLE_DIR=${OUT_DIR}/${TUMOR_ID}_${NORMAL_ID}
if [[ ! -d "${SAMPLE_DIR}" ]]; then
  log 1 "Creating Sample Directory at ${SAMPLE_DIR}"
  mkdir -p "${SAMPLE_DIR}"
fi

# step 1: BAM slicing

# bash ${PIPELINE_DIR}/utility/slice_bam.sh -v $VERBOSE \
#   -f ${TUMOR_SAMPLE} \
#   -o $TUMOR_DIR \
#   -s $SCANITD_SLICE_CHROM

# bash ${PIPELINE_DIR}/utility/slice_bam.sh -v $VERBOSE \
#   -f ${NORMAL_SAMPLE} \
#   -o $NORMAL_DIR \
#   -s $SCANITD_SLICE_CHROM

sbatch ${PIPELINE_DIR}/scripts/run_scanITD.sh -v $VERBOSE \
  -f ${TUMOR_SAMPLE} \
  -o $TUMOR_DIR \
  -s $SCANITD_SLICE_CHROM &

sbatch ${PIPELINE_DIR}/scripts/run_scanITD.sh -v $VERBOSE \
  -i $NORMAL_DIR \
  -o $NORMAL_DIR \
  -S $NORMAL_ID \
  -s $SCANITD_SLICE_CHROM &

