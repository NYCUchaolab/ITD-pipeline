#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J pindel          # Job name
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
  [ -c | --config_file args ]
  [ -s | --sample_id args; default=SAMPLE ]
  [ -o | --out_dir args; default=. ]
EOF
}

args=$(getopt -a -o Vv:hi:c:s:o: --long version,verbose:,help,input_dir:,config_file:,sample_id:,out_dir: -- "$@")

eval set -- ${args}
while :
do
  case $1 in
    -V | --version)        echo $VERSION ; exit 1;;
    -v | --verbose)        VERBOSE=$2 ; shift 2;;
    -h | --help)           usage ; exit 1;;
    -i | --input_dir)      PREFIX=$2 ; shift 2;;
    -c | --config_file)    CONFIG_FILE=$2 ; shift 2;;
    -s | --sample_id)      SAMPLE_ID=$2 ; shift 2;;
    -o | --out_dir)        OUT_DIR=$2   ; shift 2;;

    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break;;

    *) >&2 echo Unsupported option: $1
       usage 
       exit 1;;
  esac
done

check_essential_option "config_file" $CONFIG_FILE

check_dir_existence "input" $PREFIX
check_dir_existence "output" $OUT_DIR
check_file_existence "pindel configuration" $CONFIG_FILE

log 1 "Version          : ${VERSION}"
log 1 "Sample Directory : ${PREFIX}"
log 1 "Output Directory : ${OUT_DIR}"
log 1 "Sample Case ID   : ${SAMPLE_ID}"
log 1 "Configuration File : ${CONFIG_FILE}"
log 1 ""


eval "$(conda shell.bash hook)"
conda activate $PINDEL_ENV

CWD=$(pwd)

# FIXME: [ ] create p1, p2 specific counter lock
# |-> [ ] check counter lock existence and create if not created
# |-> [ ] increment counter if counter lock existed

# : << '#__COMMENT__OUT__'
pindel -f $GENOME_REF -i ${CONFIG_FILE} -o ${OUT_DIR}/${SAMPLE_ID} -T ${THREAD} > ${OUT_DIR}/${SAMPLE_ID}.log 2>&1
#__COMMENT__OUT__

check_file_existence "pindel _TD" ${OUT_DIR}/${SAMPLE_ID}_TD
check_file_existence "pindel _SI" ${OUT_DIR}/${SAMPLE_ID}_SI

grep ChrID ${OUT_DIR}/${SAMPLE_ID}_TD > ${OUT_DIR}/${SAMPLE_ID}.TD.head
grep ChrID ${OUT_DIR}/${SAMPLE_ID}_SI > ${OUT_DIR}/${SAMPLE_ID}.SI.head
cat ${OUT_DIR}/${SAMPLE_ID}.TD.head ${OUT_DIR}/${SAMPLE_ID}.SI.head > ${OUT_DIR}/all.head

check_file_existence "pindel candidate ITD" ${OUT_DIR}/all.head

cp $PINDEL_FILTERING_CONFIG $OUT_DIR
cd $OUT_DIR

# log 1 << '#__COMMENT__OUT__'
log 1 "Filtering Candidate ITD and converting into VCF format..."
perl $SOMATIC_INDEL_FILTER somatic.indel.filter.config
log 1 "Removing somatic.indel.filter.config ..."
rm somatic.indel.filter.config
cd $CWD
#__COMMENT__OUT__

for file_path in $(awk -F'\t' '{print $1}' "$CONFIG_FILE"); do
    parent_dir=$(dirname "${file_path}")
    sample_name=$(basename ${file_path} .bam)
    log 1 "Removing sample_name BAM file and BAI index"
    rm $parent_dir/$sample_name.bam
    rm $parent_dir/$sample_name.bai
    log 1 "Done removing"
    log 1 ""

    log 1 "Checking ${parent_dir} is emptied..."
    if [ -d "$parent_dir" ] && [ -z "$(ls -A "$parent_dir")" ]; then
      log 1 "${parent_dir} is empty !!"
      log 1 "Removing ${parent_dir}..."
      rmdir ${parent_dir}
      log 1 "Removed ${parent_dir}"
    fi 
    log 1 ""
done

# FIXME: [ ] remove / decrement counter lock
# |-> [ ] remove couter lock if decrement to zero, and remove file
# |-> [ ] decrement if counter is not zero, and pass

log 1 "Done ${SAMPLE_ID} Pindel ITD calling !!"
log 1 ""

conda deactivate