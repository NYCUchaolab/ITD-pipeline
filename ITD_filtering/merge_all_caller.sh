#!/bin/bash

#SBATCH -A MST109178       # Account name/project number
#SBATCH -J ITD_Consensus   # Job name
#SBATCH -p ngs186G         # Partition Name
#SBATCH -c 28              # Number of cores
#SBATCH --mem=186g         # Memory allocation
#SBATCH --mail-user=hiiluann99.dump@gmail.com    # Email
#SBATCH --mail-type=ALL    # Email notification

############### Preprocessing ############### 
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config
cd ${cwd}

pindel_dir=${cwd}/pindel
genomon_dir=${cwd}/genomon_ITD
scanITD_dir=${cwd}/scanITD
result_dir=${cwd}/result

case_ID=${1}

output_file="${result_dir}/${case_ID}.2caller.itd.filter.de.tsv"

# Check if the output file already exists and terminate if true
if [ -f "${output_file}" ]; then
    echo "Output file ${output_file} already exists. Terminating script."
    exit 1
fi
touch ${output_file}

temp_file=$(mktemp)

declare -a all_itds

read_pindel() {
    local file=${1}
    #echo "Processing pindel file: ${file}"
    while IFS=$'\t' read -r line; do
        chr=$(echo "${line}" | awk '{print $1}')
        start=$(echo "${line}" | awk '{print $2}')
        SVLEN=$(echo "${line}" | grep -oP 'SVLEN=\K[0-9]+' || echo 0)
        end=$((start + SVLEN))
        ref=$(echo "${line}" | awk '{print $4}')
        alt=$(echo "${line}" | awk '{print $5}')
        all_itds+=("pindel|${chr}|${start}|${end}|${ref}|${alt}")
    done < <(tail -n +1 "${file}")
}

read_genomon() {
    local file=${1}
    #echo "Processing genomonITD file: ${file}"
    while IFS=$'\t' read -r line; do
        chr=$(echo "${line}" | awk '{print $8}')
        start=$(echo "${line}" | awk '{print $9}')
        end=$(echo "${line}" | awk '{print $10}')
        ref="."
        alt="."
        all_itds+=("genomonITD|${chr}|${start}|${end}|${ref}|${alt}")
    done < <(tail -n +1 "${file}")
}

read_scanITD() {
    local file=${1}
    #echo "Processing scanITD file: ${file}"
    while IFS=$'\t' read -r line; do
        chr=$(echo "${line}" | awk '{print $1}')
        start=$(echo "${line}" | awk '{print $2}')
        SVLEN=$(echo "${line}" | grep -oP 'SVLEN=\K[0-9]+' || echo 0)
        end=$((start + SVLEN))
        ref=$(echo "${line}" | awk '{print $3}')
        alt=$(echo "${line}" | awk '{print $4}')
        all_itds+=("scanITD|${chr}|${start}|${end}|${ref}|${alt}")
    done < <(tail -n +1 "${file}")
}

# Process each caller file
declare -A caller_files=(
    ["pindel"]="${pindel_dir}/${case_ID}.itd.filter.de.tsv"
    ["genomonITD"]="${genomon_dir}/${case_ID}.itd.filter.de.tsv"
    ["scanITD"]="${scanITD_dir}/${case_ID}.itd.filter.de.tsv"
)

for caller in "${!caller_files[@]}"; do
    case ${caller} in
        pindel) read_pindel "${caller_files[${caller}]}" ;;
        genomonITD) read_genomon "${caller_files[${caller}]}" ;;
        scanITD) read_scanITD "${caller_files[${caller}]}" ;;
    esac
done

############### 3-2 caller ###############
declare -a valid_itds

for (( i=0; i<${#all_itds[@]}; i++ )); do
    IFS='|' read -r caller_i chr_i start_i end_i ref_i alt_i <<< "${all_itds[i]}"
    start_i_minus20=$((start_i - 20))
    end_i_plus20=$((end_i + 20))
    matched_callers=("${caller_i}")
    priority_chr=${chr_i}
    priority_start=${start_i}
    priority_end=${end_i}

    for (( j=i+1; j<${#all_itds[@]}; j++ )); do
        IFS='|' read -r caller_j chr_j start_j end_j ref_j alt_j <<< "${all_itds[j]}"

        # Only compare different callers
        if [ "${caller_i}" != "${caller_j}" ]; then
            # Check if they are on the same chromosome and overlap
            if [ "${chr_i}" == "${chr_j}" ]; then
                start_j_minus20=$((start_j - 20))
                end_j_plus20=$((end_j + 20))

                if [ ${start_i_minus20} -lt ${end_j_plus20} ] && [ ${end_i_plus20} -gt ${start_j_minus20} ]; then
                    matched_callers+=("${caller_j}")

                    # Update chr, start, end with higher-priority caller
                    if [ "${caller_j}" == "genomonITD" ]; then
                        priority_chr=${chr_j}
                        priority_start=${start_j}
                        priority_end=${end_j}
                        priority_ref=${ref_j}
                        priority_alt=${alt_j}
                    elif [ "${caller_j}" == "scanITD" ] && [ "${priority_start}" == "${start_i}" ]; then
                        priority_chr=${chr_j}
                        priority_start=${start_j}
                        priority_end=${end_j}
                        priority_ref=${ref_j}
                        priority_alt=${alt_j}
                    fi
                fi
            fi
        fi
    done

    # Output if at least 2 different callers match
    if [ ${#matched_callers[@]} -ge 2 ]; then
        # Remove duplicate callers
        unique_callers=($(echo "${matched_callers[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

        # Create output format: chr start end ref alt unique_callers
        callers=$(IFS=,; echo "${unique_callers[*]}")
        valid_itds+=("${priority_chr}\t${priority_start}\t${priority_end}\t${priority_ref}\t${priority_alt}\t${callers}")
    fi
done

# Write to output file, sorted by chromosome and start position
{
    echo -e "Chr\tStart\tEnd\tRef\tAlt\tCallers"
    for itd in "${valid_itds[@]}"; do
        echo -e "${itd}"
    done
} | sort -k1,1 -k2,2n > "${output_file}"
