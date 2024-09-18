#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J genomonITD       # Job name
#SBATCH -p ngs186G          # Partition Name (queue)
#SBATCH -c 28               # Number of cores
#SBATCH --mem=186g          # Memory allocation
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # Email notification
#SBATCH --mail-type=ALL     # When to send email (BEGIN, END, FAIL, REQUEUE, ALL)

############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

Normal_file_ID=${1}        # [1] Normal File ID
Tumor_file_ID=${2}         # [2] Tumor File ID
Normal_sample_ID=${3}      # [3] Normal Sample ID
Tumor_sample_ID=${4}       # [4] Tumor Sample ID

# Create an array of file and case IDs
IDs=("${Normal_file_ID},${Normal_sample_ID}" "${Tumor_file_ID},${Tumor_sample_ID}")

cd ${cwd}

############### Main ###############
for entry in "${IDs[@]}"; 
do
  IFS=',' read -r file_ID sample_ID <<< "$entry"
  
  if [[ -f "scanITD/${sample_ID}.itd.filter.de.tsv" ]]; then
    cat "tmp/scanITD/${file_ID}/itd.filter.de.tsv" >> "scanITD/${sample_ID}.itd.filter.de.tsv"
  else
    mv "tmp/scanITD/${file_ID}/itd.filter.de.tsv" "scanITD/${sample_ID}.itd.filter.de.tsv"
  fi
  
  sort -u -o "scanITD/${sample_ID}.itd.filter.de.tsv" "scanITD/${sample_ID}.itd.filter.de.tsv"
  
  # Clean up
  #rm -r "tmp/scanITD/${file_ID}/"

  ############### .out File ###############
  # Create the .out file if it does not exist
  [[ ! -f "tmp/scanITD.out" ]] && touch "tmp/scanITD.out"
  echo -e "${file_ID}\t${sample_ID} merge down" >> "tmp/scanITD.out"
done
