#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J genomonITD       # Job name
#SBATCH -p ngs186G          # Partition Name
#SBATCH -c 28               # Number of cores
#SBATCH --mem=186g          # Memory allocation
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # Email
#SBATCH --mail-type=ALL     # When to send email (BEGIN, END, FAIL, REQUEUE, ALL)

############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

cd ${cwd}

Normal_sample_file=${1}  # [1] Normal Sample path
Tumor_sample_file=${2}   # [2] Tumor Sample path
case_ID=${3}             # [3] Sample Case ID

output_file=./genomon_ITD/${case_ID}.itd.filter.de.tsv

# If the output file already exists, exit the script
if [[ -f "${output_file}" ]]; then
  echo "Output file ${output_file} already exists. Exiting."
  exit 0
fi
touch ${output_file}

declare -a normal_itd_list=()

############### TN filter with Chromosome Check ###############

# Read and process the Normal file
while IFS=$'\t' read -r -a normal_line; 
do
  normal_chr=${normal_line[7]}    # Assuming chromosome is in the first column (index 7)
  normal_start=${normal_line[8]}  # Assuming start position is in the 9th column (index 8)
  normal_end=${normal_line[9]}    # Assuming end position is in the 10th column (index 9)
  # Ensure values are numeric before continuing
  if [[ -n "$normal_start" && -n "$normal_end" && "$normal_start" =~ ^[0-9]+$ && "$normal_end" =~ ^[0-9]+$ ]]; then
    normal_itd_list+=("${normal_chr},${normal_start},${normal_end}")
  fi
done < <(tail -n +1 ${Normal_sample_file})

# Process the Tumor file and compare each Tumor ITD with Normal ITDs
while IFS=$'\t' read -r -a tumor_line; 
do
  tumor_chr=${tumor_line[7]}    # Assuming chromosome is in the first column (index 7)
  tumor_start=${tumor_line[8]}  # Assuming start position is in the 9th column (index 8)
  tumor_end=${tumor_line[9]}    # Assuming end position is in the 10th column (index 9)
  # Initialize flag to track if overlap is found
  overlap_found=false
  
  # Iterate through the normal ITD list to compare with the current tumor ITD
  for normal_itd in "${normal_itd_list[@]}"; 
  do
    IFS=',' read -r normal_chr normal_start normal_end <<< "${normal_itd}"
    
    # Check if the chromosomes match before proceeding with the TN filter
    if [ "${tumor_chr}" = "${normal_chr}" ]; then
      # Compare lengths and check overlap with a 20 bp buffer
      if [ $((tumor_end - tumor_start)) -ge $((normal_end - normal_start)) ]; then
        # Tumor ITD is longer or equal, check for overlap with Normal ITD
        if [ $((tumor_start - 20)) -lt ${normal_end} ] && [ $((tumor_end + 20)) -gt ${normal_start} ]; then
          overlap_found=true
          break
        fi
      else
        # Normal ITD is longer, check for overlap with Tumor ITD
        if [ $((normal_start - 20)) -lt ${tumor_end} ] && [ $((normal_end + 20)) -gt ${tumor_start} ]; then
          overlap_found=true
          break
        fi
      fi
    fi
  done
  
  # If no overlap is found and the chromosomes matched, write the Tumor ITD to the output file
  if [ "$overlap_found" = false ]; then
    echo -e "$(IFS=$'\t'; echo "${tumor_line[*]}")" >> $output_file
  fi
done < <(tail -n +1 ${Tumor_sample_file})

# Sort the output file by chromosome and start position
sort -k1,1 -k9,9n ${output_file} -o ${output_file}

############### .out File ###############
# Create the .out file if it does not exist
[[ ! -f "${cwd}/tmp/genomon_ITD.out" ]] && touch "${cwd}/tmp/genomon_ITD.out"
echo -e "${file_ID}\t${sample_ID} merge TN down" >> "${cwd}/tmp/genomon_ITD.out"