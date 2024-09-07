#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J pindel         # Job name
#SBATCH -p ngs186G           # Partition Name 等同PBS裡面的 -q Queue name
#SBATCH -c 28               # 使用的core數 請參考Queue資源設定
#SBATCH --mem=186g           # 使用的記憶體量 請參考Queue資源設定
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # email
#SBATCH --mail-type=ALL              # 指定送出email時機 可為NONE, BEGIN, END, FAIL, REQUEUE, ALL

############### preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/caller_parameters.config

conda activate ScanITD
cd ${cwd}

Normal_file_ID=${1}  # [1] Normal File ID
Tumor_file_ID=${2}   # [2] Tumor File ID
Norma_sample_ID=${3}  # [3] Normal Sample ID
Tumor_sample_ID=${4}   # [4] Tumor Sample ID

# Create an array of file and case IDs
IDs=("${Normal_file_ID},${Norma_sample_ID}" "${Tumor_file_ID},${Tumor_sample_ID}")

############### main ###############
for entry in "${IDs[@]}"; 
do
  IFS=',' read -r file_ID sample_ID <<< "$entry"
  if [[ ! -d "${cwd}/tmp/scanITD/${file_ID}" ]]; then
    mkdir -p "${cwd}/tmp/scanITD/${file_ID}"
    # Extract chromosome information from file_ID
    sample_chr=$(echo "${file_ID}" | sed 's/.*\.//')
    tmp_loc=${cwd}/tmp/scanITD/${file_ID}
    # chr1,2,3,7
    if [[ "${sample_chr}" == "chr1p" || "${sample_chr}" == "chr1q" ]]; then
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -t ${ScanITD_bed_file}/chr1.bed > ${tmp_loc}/${sample_ID}.log 2>&1 &
    elif [[ "${sample_chr}" == "chr2p" || "${sample_chr}" == "chr2q" ]]; then
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -t ${ScanITD_bed_file}/chr2.bed > ${tmp_loc}/${sample_ID}.log 2>&1 &
    elif [[ "${sample_chr}" == "chr3p" || "${sample_chr}" == "chr3q" ]]; then
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -t ${ScanITD_bed_file}/chr3.bed > ${tmp_loc}/${sample_ID}.log 2>&1 &
    elif [[ "${sample_chr}" == "chr7p" || "${sample_chr}" == "chr7q" ]]; then
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -t ${ScanITD_bed_file}/chr7.bed > ${tmp_loc}/${sample_ID}.log 2>&1 &
    else
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -t ${ScanITD_bed_file}/${sample_chr}.bed > ${tmp_loc}/${sample_ID}.log 2>&1 &
    fi
  else
    echo "${file_ID} is Done"
  fi
done
wait



