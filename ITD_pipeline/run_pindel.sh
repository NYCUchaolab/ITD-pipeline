#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J pindel          # Job name
#SBATCH -p ngs186G         # Partition Name 等同PBS裡面的 -q Queue name
#SBATCH -c 28              # 使用的core數 請參考Queue資源設定
#SBATCH --mem=186g         # 使用的記憶體量 請參考Queue資源設定
#SBATCH --mail-user=hiiluann99.dump@gmail.com  # email
#SBATCH --mail-type=ALL    # 指定送出email時機 可為NONE, BEGIN, END, FAIL, REQUEUE, ALL

############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/caller_parameters.config

conda activate Pindel
cd ${cwd}

Normal_file_ID=${1}  # [1] Normal File ID
Tumor_file_ID=${2}   # [2] Tumor File ID
case_ID=${3}         # [3] Case ID

config_file=config/${Tumor_file_ID}_${Normal_file_ID}_bam_config.txt
sample_directory=${cwd}/tmp/pindel/${Tumor_file_ID}_${Normal_file_ID}

############### Main ###############
# Create pindel tmp directory if it does not exist
if [[ ! -d "${sample_directory}" ]]; then
  mkdir -p "${sample_directory}"
  
  # 1. Run Pindel
  pindel -f $ref -i ${config_file} -o ${sample_directory}/${case_ID} -T 28 > ${sample_directory}/${case_ID}.log 2>&1
  wait

  # 2. Extract and concatenate results
  grep ChrID ${sample_directory}/${case_ID}_TD > ${sample_directory}/${case_ID}.TD.head
  grep ChrID ${sample_directory}/${case_ID}_SI > ${sample_directory}/${case_ID}.SI.head
  cat ${sample_directory}/${case_ID}.TD.head ${sample_directory}/${case_ID}.SI.head > ${sample_directory}/all.head

  # 3. Copy and process filter config
  cd ${sample_directory}
  cp ${path_to_filter_config} ${sample_directory}/
  perl ${path_to_somatic_indelfilter} ${sample_directory}/somatic.indel.filter.config > ${sample_directory}/${case_ID}.filter.log 2>&1

  # Clean up
  # rm -r ${sample_directory}

  ############### .out File ###############
  # Create the .out file if it does not exist
  [[ ! -f ${cwd}/tmp/pindel.out ]] && touch ${cwd}/tmp/pindel.out
  echo -e "${Tumor_file_ID}\t${Normal_file_ID}\t${case_ID}" >> ${cwd}/tmp/pindel.out
  
else
  echo "${Tumor_file_ID}_${Normal_file_ID} is Done"
fi
