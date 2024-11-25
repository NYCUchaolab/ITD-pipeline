#!/bin/sh

set -euo pipefail

# Global Variable
BASHRC=~/.bashrc

shopt -s expand_aliases
# source $BASHRC
source $ITD_PIPELINE_CONFIG
# source $BANNER_SH
source $TOOLS
source $READ_SAMPLE_SHEET


eval "$(conda shell.bash hook)"

VERSION=0.1.2
VERBOSE=0

INPUT_DIR=.
OUT_DIR=.



usage(){
>&2 cat << EOF
Usage: $0
   [ -V | --version ]
   [ -v | --verbose args; default=0 ]
   [ -h | --help ]
   [ -s | --sample_sheet args ]
   [ -i | --input_dir args; default=. ]
   [ -o | --out_dir args; default=. ]
   [ -t | --cache_dir args; default=${OUT_DIR} ]

EOF
}

args=$(getopt -a -o Vv:hs:i:o:t: --long version,verbose:,help,sample_sheet:,input_dir:,out_dir:,cache_dir: -- "$@")

if [[ $? -gt 0 ]]; then
  usage
fi

eval set -- ${args}

while :
do
  case $1 in
    -V | --version)        echo $VERSION ; exit 1 ;;
    -v | --verbose)        VERBOSE=$2 ; shift 2 ;;
    -h | --help)           usage ; exit 1 ;;
    -s | --sample_sheet)   SAMPLE_SHEET=$2 ; shift 2;;
    -i | --input_dir )     INPUT_DIR=$2 ; shift 2 ;;
    -o | --out_dir)        OUT_DIR=$2   ; shift 2 ;;
    -t | --cache_dir)      CACHE_DIR=$2   ; shift 2 ;;


    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    *) >&2 echo Unsupported option: $1
       usage 
       exit 1;;
  esac
done

CACHE_DIR=${CACHE_DIR:-${OUT_DIR:-"./"}}

# ================================================================ #
# Section 0: Preprocessing                                         #
# ================================================================ #

check_essential_option "sample_sheet" $SAMPLE_SHEET

check_file_existence "sample sheet" $SAMPLE_SHEET
check_dir_existence "sample" $INPUT_DIR
check_dir_existence "output" $OUT_DIR
check_dir_existence "cache" $CACHE_DIR
log 1 ""

# Create required subdirectories in OUT_DIR
# for dir in "genomonITD" "pindel" "scanITD"; do
#   check_and_create_dir $OUT_DIR $dir
# done
# log 1 ""

# Create required subdirectories in CACHE_DIR
for dir in "raw_data/genomonITD" "raw_data/pindel" "raw_data/scanITD"; do
  check_and_create_dir $CACHE_DIR $dir
done
log 1 ""


log 1 "Version          : ${VERSION}"
log 1 "Sample Sheet     : ${SAMPLE_SHEET}"
log 1 "Sample Directory : ${INPUT_DIR}"
log 1 "Output Directory : ${OUT_DIR}"
log 1 "Cache Directory  : ${CACHE_DIR}"
log 1 ""

: << 'TODO_LIST'
1. read the sample sheet 
2. pindel pipeline:
  |-> slice (2 part)
  |-> pindel (calling)
  |-> pindel2vcf (SI & TD)
3. scanITD pipeline:
  |->  slice (28 BAM) 
4. genomon-ITDetector 
TODO_LIST

shopt -s nocasematch

# ================================================================ #
# Section 1: Sample Sheet Reading                                  #
# ================================================================ #

parse_sample_sheet $SAMPLE_SHEET
check_variables_set Case_ID Tumor_fileID Normal_fileID Tumor_fileID

# ================================================================ #
# Section 2: ITD Calling                                           #
# ================================================================ #

TUMOR_BAM=$INPUT_DIR/$Tumor_fileID.bam
NORMAL_BAM=$INPUT_DIR/$Normal_fileID.bam

check_file_existence "tumor BAM" $TUMOR_BAM
check_file_existence "normal BAM" $NORMAL_BAM

log 1 "tumor BAM file   : $TUMOR_BAM"
log 1 "normal BAM file  : $NORMAL_BAM"
log 1 ""

check_bai_existence "${TUMOR_BAM}" 
check_bai_existence "${NORMAL_BAM}" 


# step 1: pindel calling
bash $PIPELINE_DIR/scripts/pindel_pipeline.sh -v $VERBOSE \
  -s $Case_ID \
  -t $TUMOR_BAM \
  -n $NORMAL_BAM \
  -o $CACHE_DIR/raw_data/pindel &
 
# step 2: scanITD calling
bash $PIPELINE_DIR/scripts/scanITD_pipeline.sh -v $VERBOSE \
  -s $Case_ID \
  -t $TUMOR_BAM \
  -n $NORMAL_BAM \
  -o $CACHE_DIR/raw_data/scanITD &

# step 3: genomon-ITDetector
sbatch $PIPELINE_DIR/scripts/run_genomonITD.sh -v $VERBOSE \
  -f $TUMOR_BAM \
  -o $CACHE_DIR/raw_data/genomonITD/${Tumor_fileID} &
  
sbatch $PIPELINE_DIR/scripts/run_genomonITD.sh -v $VERBOSE \
  -f $NORMAL_BAM \
  -o $CACHE_DIR/raw_data/genomonITD/${Normal_fileID} &

# ================================================================ #
# Section 3: ITD Merging (2-caller)                                #
# ================================================================ #

# bash merge_caller.sh ...
