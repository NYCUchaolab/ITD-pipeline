#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J ScanITD         # Job name
#SBATCH -p ngs186G         # Partition Name (Queue name)
#SBATCH -c 28              # Number of cores to use, according to queue settings
#SBATCH --mem=186g         # Amount of memory to use, according to queue settings
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # Email address
#SBATCH --mail-type=ALL    # Email triggers (BEGIN, END, FAIL, REQUEUE, ALL)

############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

conda activate ScanITD
cd ${cwd}

Normal_file_ID=${1}  # Normal File ID
Tumor_file_ID=${2}   # Tumor File ID
Normal_sample_ID=${3}  # Normal Sample ID
Tumor_sample_ID=${4}   # Tumor Sample ID

# Create an array of file and sample IDs
IDs=("${Normal_file_ID},${Normal_sample_ID}" "${Tumor_file_ID},${Tumor_sample_ID}")

############### Main loop ###############
for entry in "${IDs[@]}"; 
do
  IFS=',' read -r file_ID sample_ID <<< "$entry"
  
  # Extract chromosome
  sample_chr=$(echo "${file_ID}" | sed 's/.*\.//')
  
  # Make the parameters needed for scanITD
  tmp_loc="${cwd}/tmp/scanITD/${file_ID}"
  
  # Create temporary directory if it doesn't exist
  if [[ ! -d "${tmp_loc}" ]]; then
    mkdir -p "${tmp_loc}"
    
    # 1. Run scanITD by chromosome
    if [[ "${sample_chr}" == "chr1p" || "${sample_chr}" == "chr1q" ]]; then
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -l 3 -t ${ScanITD_bed_file}/chr1.bed > ${tmp_loc}/${sample_ID}.log 2>&1
    elif [[ "${sample_chr}" == "chr2p" || "${sample_chr}" == "chr2q" ]]; then
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -l 3 -t ${ScanITD_bed_file}/chr2.bed > ${tmp_loc}/${sample_ID}.log 2>&1
    elif [[ "${sample_chr}" == "chr3p" || "${sample_chr}" == "chr3q" ]]; then
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -l 3 -t ${ScanITD_bed_file}/chr3.bed > ${tmp_loc}/${sample_ID}.log 2>&1
    elif [[ "${sample_chr}" == "chr7p" || "${sample_chr}" == "chr7q" ]]; then
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -l 3 -t ${ScanITD_bed_file}/chr7.bed > ${tmp_loc}/${sample_ID}.log 2>&1
    else
      python ${path_to_ScanITD}/ScanITD.py -i slicebam/${file_ID}.bam -r ${ref} -o ${tmp_loc}/${sample_ID} -l 3 -t ${ScanITD_bed_file}/${sample_chr}.bed > ${tmp_loc}/${sample_ID}.log 2>&1
    fi

    # 2. Log output
    [[ ! -f ${cwd}/tmp/scanITD.out ]] && touch ${cwd}/tmp/scanITD.out
    echo -e "${file_ID}\tScanITD Calling finish" >> ${cwd}/tmp/scanITD.out
  else
    [[ ! -f ${cwd}/tmp/scanITD.out ]] && touch ${cwd}/tmp/scanITD.out
    echo "${file_ID} is Done" >> ${cwd}/tmp/scanITD.out
  fi
done
