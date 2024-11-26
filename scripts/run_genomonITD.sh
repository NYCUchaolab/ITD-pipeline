#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J genomonITD         # Job name
#SBATCH -p ngs186G           # Partition Name 等同PBS裡面的 -q Queue name
#SBATCH -c 28           # 使用的core數 請參考Queue資源設定
#SBATCH --mem=186g           # 使用的記憶體量 請參考Queue資源設定
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # email
#SBATCH --mail-type=ALL              # 指定送出email時機 可為NONE, BEGIN, END, FAIL, REQUEUE, ALL

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
OUT_DIR=.
VERBOSE=0

usage(){
>&2 cat << EOF
Usage: $0
  [ -V | --version ]
  [ -v | --verbose args; default=0 ]
  [ -h | --help ]
  [ -f | --sample_file args ]
  [ -o | --out_dir args; default=./ ]
EOF
}

args=$(getopt -a -o Vv:hf:o: --long version,verbose:,help,sample_file:,out_dir: -- "$@")

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
    -f | --sample_file)    SAMPLE_BAM=$2 ; shift 2 ;;
    -o | --out_dir)        OUT_DIR=$2 ; shift 2 ;;

    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    *) >&2 echo Unsupported option: $1
       usage 
       exit 1;;
  esac
done

log 1 "Version          : ${VERSION}"
log 1 "Sample BAM File  : ${SAMPLE_BAM}"
log 1 "Output Directory : ${OUT_DIR}"
log 1 ""

SAMPLE_ID=$(basename "$SAMPLE_BAM" .bam)



# [X] in addition of itd_list checking, adding lock file check
# |-> [X] if lock file not exist create a lock file
# |-> [X] if lokc file exist end program

if [[ ! -d "${OUT_DIR}" ]]; then
  log 1 "Creating Sample Directory at ${OUT_DIR}"
  mkdir -p "${OUT_DIR}"
  log 1 "Done Creating Sample Directory !"
  log 1 ""
fi

LOCKFILE="$OUT_DIR/genomonITD_${SAMPLE_ID}.lock"

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

if [ -f $OUT_DIR/itd_list.tsv ]; then
  log 1 "${OUT_DIR}/itd_list.tsv existed !!"
  log 1 "Skip calling ${SAMPLE_ID} ITD in ${partition} with Genomon-ITDetector...}"
  log 1 ""
  
  exit 0
fi




PARENT_DIR=$(dirname "${OUT_DIR}")
TMP_DIR=$(mktemp -d "${PARENT_DIR}/tmp_XXXXXX")

WORK_DIR=$(pwd)

if [ -f $OUT_DIR/itd_list.tsv ]; then
  log 1 "${SAMPLE_ID}'s genomonITD result existed in $OUT_DIR !!"
  log 1 "exiting ${SAMPLE_ID} genomon-ITDetector calling process"
  log 1 ""

  rmdir  $TMP_DIR
  exit 0
fi

cd ${GENOMON_ITD_DIR}
conda activate $GENOMON_ITD_ENV

./detectITD.sh $SAMPLE_BAM $TMP_DIR ${SAMPLE_ID} $GENOMON_ITD_CONFIG

[[ ! -f $TMP_DIR/itd_list.tsv ]] && touch $TMP_DIR/itd_list.tsv
mv $TMP_DIR/* $OUT_DIR/
rmdir  $TMP_DIR

cd $WORK_DIR
conda deactivate

