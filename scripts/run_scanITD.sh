#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J scanITD          # Job name
#SBATCH -p ngs186G         # Partition Name 等同PBS裡面的 -q Queue name
#SBATCH -c 28              # 使用的core數 請參考Queue資源設定
#SBATCH --mem=186g         # 使用的記憶體量 請參考Queue資源設定
#SBATCH --mail-user=hiiluann99.dump@gmail.com  # email
#SBATCH --mail-type=ALL    # 指定送出email時機 可為NONE, BEGIN, END, FAIL, REQUEUE, ALL

set -euo pipefail
BASHRC=~/.bashrc
# source $BASHRC

shopt -s expand_aliases

source $ITD_PIPELINE_CONFIG
source $BANNER_SH
source $TOOLS

VERSION=0.1.1
VERBOSE=0
PREFIX=.
SAMPLE_ID=SAMPLE
OUT_DIR=$PREFIX

usage(){
>&2 cat << EOF
Usage: $0
  [ -V | --version ]
  [ -v | --verbose args; default=0 ]
  [ -h | --help ]
  [ -i | --input_dir args; default=. ]
  [ -o | --out_dir args; default=. ]
  [ -S | --sample_id args; default=SAMPLE ]
  [ -s | --slice_file args ]
EOF
}

args=$(getopt -a -o Vv:hi:S:s:o: --long version,verbose:,help,input_dir:,out_dir:,slice_file:,sample_id: -- "$@")

eval set -- ${args}
while :
do
  case $1 in
    -V | --version)        echo $VERSION ; exit 1;;
    -v | --verbose)        VERBOSE=$2 ; shift 2;;
    -h | --help)           usage ; exit 1;;
    -i | --input_dir)      PREFIX=$2 ; shift 2;;
    -o | --out_dir)        OUT_DIR=$2   ; shift 2;;
    -S | --sample_id)      SAMPLE_ID=$2 ; shift 2;;
    -s | --slice_file)     SLICE_CHROM_DB=$2; shift 2;;

    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break;;

    *) >&2 echo Unsupported option: $1
      usage 
      exit 1;;
  esac
done

# check_essential_option "config_file" $CONFIG_FILE

check_dir_existence "input" $PREFIX
check_dir_existence "output" $OUT_DIR
check_file_existence "slice configuration" $SLICE_CHROM_DB


log 1 "Version          : ${VERSION}"
log 1 "Sample Directory : ${PREFIX}"
log 1 "Output Directory : ${OUT_DIR}"
log 1 "Sample Case ID   : ${SAMPLE_ID}"
log 1 "Slicing Configuration File : ${SLICE_CHROM_DB}"
log 1 ""

eval "$(conda shell.bash hook)"
conda activate $SCANITD_ENV

declare -A partition_array

# reading slicing chromosome information
for partition in $(awk -F= '{print $1}' "$SLICE_CHROM_DB"); do
    partition_array["$partition"]=$partition
done

for partition in ${partition_array[@]}; do
  case "${partition}" in
  "chr1p" | "chr1q")    bed_file="${SCANITD_BED_FILE}/chr1.bed" ;;
  "chr2p" | "chr2q")    bed_file="${SCANITD_BED_FILE}/chr2.bed" ;;
  "chr3p" | "chr3q")    bed_file="${SCANITD_BED_FILE}/chr3.bed" ;;
  "chr7p" | "chr7q")    bed_file="${SCANITD_BED_FILE}/chr7.bed" ;;
  *)                    bed_file="${SCANITD_BED_FILE}/${partition}.bed" ;;
  esac    
  
  log 1 "running scanITD on $SAMPLE_ID:  $partition"
  log 1 "bed file: ${bed_file}"
  log 1 ""


  # log 1 << '#__COMMENT__OUT__'
  (
    # Execute the python script
    python ${SCANITD_DIR}/ScanITD.py \
      -i $PREFIX/$SAMPLE_ID.$partition.bam \
      -r $GENOME_REF \
      -o $OUT_DIR/$partition \
      -t $bed_file \
      -l 3 -f 0 -c 3

    # Remove the input file after the job is done
    rm -f $PREFIX/$SAMPLE_ID.$partition.bam
    rm -f $PREFIX/$SAMPLE_ID.$partition.bai
    log 1 "Removed input file: $PREFIX/$SAMPLE_ID.$partition.bam"
  ) &
    # -l: minimal ITD length to report, -f: minimal VAF, -c: mininal ovservation count 
  #__COMMENT__OUT__
done

wait 
log 1 ""





log 1 "${SAMPLE_ID} Done !!"
log 1 ""
conda deactivate