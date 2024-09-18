#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J genomonITD         # Job name
#SBATCH -p ngs186G           # Partition Name
#SBATCH -c 28                # Number of cores
#SBATCH --mem=186g           # Memory allocation
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # email
#SBATCH --mail-type=ALL      # Send email notifications

############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

Normal_file_ID=${1}  # [1] Normal File ID
Tumor_file_ID=${2}   # [2] Tumor File ID
Normal_sample_ID=${3} # [3] Normal Sample ID
Tumor_sample_ID=${4} # [4] Tumor Sample ID

# Create an array of file and case IDs
IDs=("${Normal_file_ID},${Normal_sample_ID}" "${Tumor_file_ID},${Tumor_sample_ID}")

############### Main ###############
for entry in "${IDs[@]}"; 
do
  IFS=',' read -r file_ID sample_ID <<< "$entry"
  sample_chr=$(echo "${file_ID}" | sed 's/.*\.//')
  file_ID_change=${file_ID:0:20}.${sample_chr}

  cd ${cwd}/tmp/genomon_ITD/${file_ID_change}
  Input_itd_file=${cwd}/tmp/genomon_ITD/${file_ID_change}/itd_list.tsv
  declare -a itd_list=()
  
  if [[ -f itd.filter.de.tsv ]]; then
    echo -e "${file_ID}\titd.filter.de.tsv already exists. Exiting."  >> ${cwd}/tmp/genomon_ITD.out
    continue
  fi
  touch itd.filter.de.tsv
  # Read the ITD file starting from line 16
  while IFS=$'\t' read -r -a line; 
  do
    start_POS=${line[8]}  # [8]: start position
    end_POS=${line[9]}    # [9]: end position
    
    # Check if the length of the ITD region is between 3 and 300
    if [ $((${end_POS} - ${start_POS})) -gt 3 ] && [ $((${end_POS} - ${start_POS})) -lt 300 ]; then
      overlap_found=false
      
      # Iterate over each ITD in the list to check for overlaps
      for itd in "${itd_list[@]}"; do
        IFS=',' read -r list_start_POS list_end_POS <<< "$itd"
        
        if [ $((${list_end_POS} - ${list_start_POS})) -ge $((${end_POS} - ${start_POS})) ]; then
          # Existing ITD is longer and overlaps with the current ITD
          if [ $((${list_start_POS} - 20)) -lt ${end_POS} ] && [ $((${list_end_POS} + 20)) -gt ${start_POS} ]; then
            overlap_found=true
            break
          fi
        else
          # Current ITD is longer and overlaps with the existing ITD
          if [ $((${start_POS} - 20)) -lt ${list_end_POS} ] && [ $((${end_POS} + 20)) -gt ${list_start_POS} ]; then
            itd_list=("${itd_list[@]/$itd/$start_POS,$end_POS}")
            overlap_found=true
            break
          fi
        fi
      done
  
      # If no overlap was found, add the new ITD
      if [ "$overlap_found" = false ]; then
        matched=false
        for itd in "${itd_list[@]}"; 
        do
          if [ "$itd" = "$start_POS,$end_POS" ]; then
            matched=true
            break
          fi
        done
        if [ "$matched" = false ]; then
          itd_list+=("$start_POS,$end_POS")
        fi
      fi
    fi
  done < <(tail -n +1 $Input_itd_file)
  
  ############### Output ###############
  touch itd.filter.de.tsv
  for itd in "${itd_list[@]}"; 
  do
    IFS=',' read -r itd_start itd_end <<< "$itd"
    while IFS=$'\t' read -r -a line; 
    do
      start_POS=${line[8]}  # [8]: start position
      end_POS=${line[9]}    # [9]: end position
      if [ "$itd_start" -eq "$start_POS" ] && [ "$itd_end" -eq "$end_POS" ]; then
        echo -e "$(IFS=$'\t'; echo "${line[*]}")" >> itd.filter.de.tsv
        #echo "${line[@]}" >> itd.filter.de.tsv
      fi
    done < <(tail -n +1 $Input_itd_file)
  done
done

############### .out File ###############
# Create the .out file if it does not exist
[[ ! -f ${cwd}/tmp/genomon_ITD.out ]] && touch ${cwd}/tmp/genomon_ITD.out
echo -e "${Normal_sample_ID}\t${Tumor_sample_ID} filter finish" >> ${cwd}/tmp/genomon_ITD.out