#!/bin/sh

set -euo pipefail

slice_chr_bam(){
  OUT_DIR=$1
  FILE=$2;
  CHROM_NAME=$3;
  CHROM=$4;
  FILE_ID=$(basename "$FILE" .bam)
  
  if [ -f "${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bam" ]; then
    log 1 "${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bam existed !!"
    log 1 "Skip slicing $CHROM_NAME in ${FILE}"
    log 1 ""

  else 
    log 1 "Slicing $CHROM_NAME in ${FILE}..."
    samtools view -@ $THREAD $FILE ${CHROM} -b > "${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bam"
    log 1 "Done slicing $CHROM_NAME"
    log 1 ""
  fi  
  
  if [ -f "${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bai" ]; then
    log 1 "${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bai existed !!"
    log 1 "Skip indexing ${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bam"
    log 1 ""
    
  else
    log 1 "Creating index file for ${FILE_ID}.${CHROM_NAME}.bam"
    samtools index "${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bam"
    mv ${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bam.bai ${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bai 
    log 1 "Done indexing"
    log 1 ""
  fi
}

# Global Variable
BASHRC=~/.bashrc

shopt -s expand_aliases
# source $BASHRC
source $ITD_PIPELINE_CONFIG
source $BANNER_SH
source $TOOLS

eval "$(conda shell.bash hook)"
conda activate $SAMTOOLS_ENV


VERSION=0.1.1
VERBOSE=0
THREAD=20
SLICE_CHROM_DB=${PIPELINE_DIR}/tools/scanITD_slice_chrom.txt
OUT_DIR=./

usage(){
>&2 cat << EOF
Usage: $0
  [ -V | --version ]
  [ -v | --verbose args; default=0 ]
  [ -h | --help ]
  [ -f | --file args ]
  [ -o | --out_dir args; default=./ ]
  [ -s | --slice_file args; default=tools/scanITD_slice_chrom.txt ]
EOF
} 

args=$(getopt -a -o Vv:hf:o:s: --long version,verbose:,help,file:,out_dir:,slice_file: -- "$@")

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
    -f | --file)           FILE_NAME=$2 ; shift 2;;
    -o | --out_dir)        OUT_DIR=$2   ; shift 2;;
    -s | --slice_file)     SLICE_CHROM_DB=$2; shift 2;;

    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break;;

    *) >&2 echo Unsupported option: $1
       usage 
       exit 1;;
  esac
done

check_essential_option "file" $FILE_NAME
# current setting default slicing file to 28 partition (ScanITD)
# check_essential_option "slice_file" $SLICE_CHROM_DB

# checking sample sheet existent
check_file_existence "sample BAM" $FILE_NAME
check_dir_existence "output" $OUT_DIR
check_file_existence "slicing configuration" $SLICE_CHROM_DB 

log 1 "Version          : ${VERSION}"
log 1 "Sample BAM File  : ${FILE_NAME}"
log 1 "Output Directory : ${OUT_DIR}"
log 1 "Slicing Configuration File : ${SLICE_CHROM_DB}"
log 1 ""

declare -A CHROM_NAME_ORD_ARR

# reading slicing chromosome information
log 1 "Reading BAM slicing partition information in ${SLICE_CHROM_DB}..."
while IFS="=" read -r key value; do
    CHROM_NAME_ORD_ARR["$key"]="$value"
    log 1 "partition ${key}: ${value}"
done < $SLICE_CHROM_DB
log 1 ""

for CHROM_NAME in "${!CHROM_NAME_ORD_ARR[@]}"; do
  CHROM=${CHROM_NAME_ORD_ARR[$CHROM_NAME]}
  slice_chr_bam $OUT_DIR $FILE_NAME $CHROM_NAME "$CHROM"
done

conda deactivate