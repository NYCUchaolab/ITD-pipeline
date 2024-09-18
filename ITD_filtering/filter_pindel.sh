#!/bin/sh

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J genomonITD       # Job name
#SBATCH -p ngs186G          # Partition Name
#SBATCH -c 28               # Number of cores
#SBATCH --mem=186g          # Memory requirement
#SBATCH --mail-user=hiiluann99.dump@gmail.com
#SBATCH --mail-type=ALL     # Email notifications

############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

conda activate Pindel

Normal_file_ID=${1}  # [1] Normal File ID
Tumor_file_ID=${2}   # [2] Tumor File ID
case_ID=${3}         # [3] Case ID

sample_directory=${cwd}/tmp/pindel/${Tumor_file_ID}_${Normal_file_ID}
cd ${sample_directory}


# Ensure the output file exists
if [[ -f itd.filter.de.tsv ]]; then
  echo -e "${file_ID}\titd.filter.de.tsv already exists. Exiting."  >> ${cwd}/tmp/pindel.out
  exit 1
fi
touch itd.filter.de.tsv
############### Main ###############
Input_itd_file=./indel.filter.output

# Initialize the ITD list
declare -a itd_list=()

# Process the file and build the list and map
while IFS=$'\t' read -r -a line; 
do
  start_POS=${line[1]}  # start pos
  SVLEN=$(echo "${line[7]}" | grep -oP 'SVLEN=\K[0-9]+' || echo 0)  # Default to 0 if not found
  end_POS=$(($start_POS + $SVLEN))  # end pos

  # Check if the length of the ITD region is between 3 and 300
  if [ $((${end_POS} - ${start_POS})) -gt 3 ] && [ $((${end_POS} - ${start_POS})) -lt 300 ]; then
    overlap_found=false
    # Iterate over each ITD in the list to check for overlaps
    for itd in "${itd_list[@]}"; do
      IFS=',' read -r list_start_POS list_end_POS <<< "$itd"
      # Determine which ITD is longer
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
done < <(tail -n +17 $Input_itd_file)

# Write the matching rows to itd.filter.de1.tsv
for itd in "${itd_list[@]}"; do
    IFS=',' read -r itd_start itd_end <<< "$itd"
    while IFS=$'\t' read -r -a line; do
        start_POS=${line[1]}  # start pos
        SVLEN=$(echo "${line[7]}" | grep -oP 'SVLEN=\K[0-9]+' || echo 0)  # Default to 0 if not found
        end_POS=$(($start_POS + $SVLEN))  # end pos
        if [ "$itd_start" -eq "$start_POS" ] && [ "$itd_end" -eq "$end_POS" ]; then
            #echo "Writing matching line to itd.filter.de1.tsv: ${line[@]}"
            echo -e "$(IFS=$'\t'; echo "${line[*]}")" >> itd.filter.de.tsv
            #echo "${line[@]}" >> itd.filter.de.tsv
        fi
    done < <(tail -n +17 $Input_itd_file)
done

############### .out File ###############
# Create the .out file if it does not exist
[[ ! -f ${cwd}/tmp/pindel.out ]] && touch ${cwd}/tmp/pindel.out
echo -e "${case_ID}\t${Normal_file_ID}\t${Tumor_file_ID} filter finish" >> ${cwd}/tmp/pindel.out