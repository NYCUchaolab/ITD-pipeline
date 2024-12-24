#!/bin/sh

# Source the parameters from the config file

#
Sample_sheet=$1
cancer=$2
count=0

header=$(head -n 1 "$Sample_sheet" | tr ',' '\t')

# Loop through each line after the header (for tumor samples)
while IFS=$',' read -r -a sample; do
  Cancer_type=${sample[6]: -3:1}
  Case_ID=${sample[5]}
  
  # Check if it's a tumor sample
  if [[ "$Cancer_type" == "0" ]]; then
    tumor_sample=$(printf "%s\t" "${sample[@]}")  # Store the tumor sample, tab-separated
    tumor_sample=${tumor_sample%$'\t'}  # Remove the trailing tab
    
    # Loop through each line after the header (for normal samples)
    while IFS=$',' read -r -a sample_par; do
      Cancer_type_par=${sample_par[6]: -3:1}
      Case_ID_par=${sample_par[5]}
      
      # Check if it's a normal sample and if the Case_ID matches
      if [[ "$Cancer_type_par" == "1" && "$Case_ID" == "$Case_ID_par" ]]; then
        ((count++))
        normal_sample=$(printf "%s\t" "${sample_par[@]}")  # Format normal sample as tab-separated
        normal_sample=${normal_sample%$'\t'}  # Remove the trailing tab
        #
        [ ! -d /home/hiiluann99/TCGA_whole/${cancer}_samplesheet ] && mkdir /home/hiiluann99/TCGA_whole/${cancer}_samplesheet
        config_file=/home/hiiluann99/TCGA_whole/${cancer}_samplesheet/${cancer}_sample_${count}.tsv
        #
        touch "$config_file"
        echo -e "$header" > "$config_file"
        echo -e "$normal_sample" >> "$config_file"
        echo -e "$tumor_sample" >> "$config_file"
      fi
    done < <(tail -n +2 "$Sample_sheet")
  fi
done < <(tail -n +2 "$Sample_sheet")

