#!/bin/sh

# Source the parameters from the config file
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config
cd ${cwd}

############### make config ###############
Tumor_sample_sheet=$1
Normal_sample_sheet=$2

tail -n +2 $Tumor_sample_sheet | while IFS=$'\t' read -r -a Tumor_sample
do
  Tumor_file_ID=${Tumor_sample[0]}   # [0] file ID
  Tumor_case_ID=${Tumor_sample[5]}   # [5] case ID

  tail -n +2 $Normal_sample_sheet | while IFS=$'\t' read -r -a Normal_sample
  do
    Normal_file_ID=${Normal_sample[0]}   # [0] file ID
    Normal_case_ID=${Normal_sample[5]}   # [5] case ID
    
    # If Tumor_case_ID and Normal_case_ID are equal, create the config file
    if [ "$Tumor_case_ID" = "$Normal_case_ID" ]; then
      for slice_id in "${slice_ID[@]}" # Loop over slice_ID array
      do
        Tumor_bam_file_path=slicebam/${Tumor_file_ID}.${slice_id}.bam
        Normal_bam_file_path=slicebam/${Normal_file_ID}.${slice_id}.bam
        #
        config_file=config/${Tumor_file_ID}.${slice_id}_${Normal_file_ID}.${slice_id}_bam_config.txt
        touch $config_file
        echo -e "${Normal_bam_file_path}\t250\t${Normal_case_ID}_N" > $config_file
        echo -e "${Tumor_bam_file_path}\t250\t${Tumor_case_ID}_T" >> $config_file
      done
    fi
  done
done