#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J genomonITD         # Job name
#SBATCH -p ngs186G           # Partition Name 等同PBS裡面的 -q Queue name
#SBATCH -c 28           # 使用的core數 請參考Queue資源設定
#SBATCH --mem=186g           # 使用的記憶體量 請參考Queue資源設定
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # email
#SBATCH --mail-type=ALL              # 指定送出email時機 可為NONE, BEGIN, END, FAIL, REQUEUE, ALL


############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/caller_parameters.config

conda activate GenomonITD
cd ${cwd}

Normal_file_ID=${1}  # [1] Normal File ID
Tumor_file_ID=${2}   # [2] Tumor File ID
Norma_sample_ID=${3}  # [3] Normal Sample ID
Tumor_sample_ID=${4}   # [4] Tumor Sample ID

# Create an array of file and case IDs
IDs=("${Normal_file_ID},${Norma_sample_ID}" "${Tumor_file_ID},${Tumor_sample_ID}")

############### Main ###############
for entry in "${IDs[@]}"; 
do
  IFS=',' read -r file_ID sample_ID <<< "$entry"
  #
  sample_chr=$(echo "${file_ID}" | sed 's/.*\.//')
  file_ID_change=${file_ID:0:20}.${sample_chr}
  # Create the genomon_ITD tmp directory if it does not exist
  if [[ ! -d "${cwd}/tmp/genomon_ITD/${file_ID_change}" ]]; then
    mkdir -p "${cwd}/tmp/genomon_ITD/${file_ID_change}"
    
    # ITD detection with genomon-ITDetector
    bam_file=${cwd}/slicebam/${file_ID}.bam
    tmp_loc=${cwd}/tmp/genomon_ITD/${file_ID_change}
    # Run ITD detection
    cd ${path_to_GenomonITDetector38}
    ./detectITD.sh $bam_file $tmp_loc ${file_ID_change} > ${tmp_loc}/${file_ID_change}.log 2>&1 &
  else
    echo "${file_ID} is Done"
  fi
    ############### .out File ###############
  # Create the .out file if it does not exist
  
  if [[ ! -f itd_list.tsv ]] && touch itd_list.tsv

done
  
