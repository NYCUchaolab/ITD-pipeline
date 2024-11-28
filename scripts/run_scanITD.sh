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
SAMPLE_ID=SAMPLE
OUT_DIR=.

usage(){
>&2 cat << EOF
Usage: $0
  [ -V | --version ]
  [ -v | --verbose args; default=0 ]
  [ -h | --help ]
  [ -f | --file args ]
  [ -o | --out_dir args; default=. ]
  [ -s | --slice_file args ]
EOF
}

args=$(getopt -a -o Vv:hf:s:o: --long version,verbose:,help,file:,out_dir:,slice_file: -- "$@")

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

# check_essential_option "config_file" $CONFIG_FILE

check_essential_option "file" $FILE_NAME

check_file_existence "sample BAM" $FILE_NAME
check_dir_existence "output" $OUT_DIR
check_file_existence "slice configuration" $SLICE_CHROM_DB

SAMPLE_ID=$(basename "$FILE_NAME" .bam)

log 1 "Version          : ${VERSION}"
log 1 "Sample BAM File  : ${FILE_NAME}"
log 1 "Output Directory : ${OUT_DIR}"
log 1 "Sample Case ID   : ${SAMPLE_ID}"
log 1 "Slicing Configuration File : ${SLICE_CHROM_DB}"
log 1 ""

eval "$(conda shell.bash hook)"
conda activate $SCANITD_ENV

# [X] create a lock file if not exist
# |-> [X] if lock file not exist: create a lock file
# |-> [X] if lock file exist: end program

LOCKFILE="$OUT_DIR/scanITD_${SAMPLE_ID}.lock"

if ! (set -o noclobber; echo "$$" > $LOCKFILE) 2>/dev/null; then
  log 0 "Lock file exists. Another instance might be running. Exiting program."
  log 0 ""
  exit 3 
else
  log 1 "Created Lock file: ${LOCKFILE}"
  log 1 ""
fi

# [X] remove lock file
trap exit_lock_cleanup INT TERM EXIT

declare -A partition_array 

bash ${PIPELINE_DIR}/utility/slice_bam.sh -v $VERBOSE \
  -f $FILE_NAME \
  -o $OUT_DIR \
  -s $SCANITD_SLICE_CHROM

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
    if [ -f "${OUT_DIR}/${partition}.itd.vcf" ]; then
      log 1 "${OUT_DIR}/${partition}.itd.vcf existed !!"
      log 1 "Skip calling ${SAMPLE_ID} ITD in ${partition} with ScanITD..."
      log 1 ""

      if [ -f "$OUT_DIR/$SAMPLE_ID.$partition.bam" ]; then
        rm -f $OUT_DIR/$SAMPLE_ID.$partition.bam
      fi

      if [ -f "$OUT_DIR/$SAMPLE_ID.$partition.bai" ]; then
        rm -f $OUT_DIR/$SAMPLE_ID.$partition.bai
      fi

    else 
      log 1 "Calling ${SAMPLE_ID} ITD in ${partition} with ScanITD...}"
      python ${SCANITD_DIR}/ScanITD.py \
        -i $OUT_DIR/$SAMPLE_ID.$partition.bam \
        -r $GENOME_REF \
        -o $OUT_DIR/$partition \
        -t $bed_file \
        -l 3 -f 0 -c 3
      
      log 1 "Done calling ${SAMPLE_ID} ITD in ${partition} !!"

      # Remove the input file after the job is done
      rm -f $OUT_DIR/$SAMPLE_ID.$partition.bam
      rm -f $OUT_DIR/$SAMPLE_ID.$partition.bai
      log 1 "Removed input file: $OUT_DIR/$SAMPLE_ID.$partition.bam"
      log 1 ""
    fi  
  ) &
    # -l: minimal ITD length to report, -f: minimal VAF, -c: mininal ovservation count 
  #__COMMENT__OUT__
done

wait 
log 1 ""




log 1 "${SAMPLE_ID} Done !!"
log 1 ""
conda deactivate