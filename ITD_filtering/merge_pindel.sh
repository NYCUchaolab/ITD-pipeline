#!/bin/sh

#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J genomonITD         # Job name
#SBATCH -p ngs186G           # Partition Name 等同PBS裡面的 -q Queue name
#SBATCH -c 28           # 使用的core數 請參考Queue資源設定
#SBATCH --mem=186g           # 使用的記憶體量 請參考Queue資源設定
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # email
#SBATCH --mail-type=ALL              # 指定送出email時機 可為NONE, BEGIN, END, FAIL, REQUEUE, ALL


############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

Normal_file_ID=${1}  # [1] Normal File ID
Tumor_file_ID=${2}   # [2] Tumor File ID
case_ID=${3}         # [3] Case ID

sample_directory=${cwd}/tmp/pindel/${Tumor_file_ID}_${Normal_file_ID}

cd ${sample_directory}

############### Main ###############
if [[ -f "${cwd}/pindel/${case_ID}.itd.filter.de.tsv" ]]; then
  cat "${sample_directory}/itd.filter.de.tsv" >> "${cwd}/pindel/${case_ID}.itd.filter.de.tsv"
else
  mv "${sample_directory}/itd.filter.de.tsv" "${cwd}/pindel/${case_ID}.itd.filter.de.tsv"
fi

sort -u -o "${cwd}/pindel/${case_ID}.itd.filter.de.tsv" "${cwd}/pindel/${case_ID}.itd.filter.de.tsv"

# Clean up
#rm -r ${sample_directory}

############### .out File ###############
# Create the .out file if it does not exist
[[ ! -f "${cwd}/tmp/pindel.out" ]] && touch "${cwd}/tmp/pindel.out"
echo -e "${file_ID}\t${sample_ID} merge down" >> "${cwd}/tmp/pindel.out"

