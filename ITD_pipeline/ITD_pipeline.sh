#!/bin/sh

# Source the parameters from the config file

source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config
cd ${cwd}
############### slice bam ###############
#bash ${pipeline_path}/Slice_bam.sh
echo "Slice_bam.sh Done"

############### make config ###############
Tumor_sample_sheet=$1
Normal_sample_sheet=$2

#bash ${pipeline_path}/Make_config.sh ${Tumor_sample_sheet} ${Normal_sample_sheet}
echo "Make_config.sh Done"

############### run all caller ###############
for config_file in config/*.txt
do
  # Extract information from the configuration file
  Normal_file_ID=$(awk 'NR==1{print $1}' $config_file | sed 's#slicebam/##; s/.bam$//')
  Tumor_file_ID=$(awk 'NR==2{print $1}' $config_file | sed 's#slicebam/##; s/.bam$//')
  Normal_sample_ID=$(awk 'NR==1{print $3}' $config_file)
  Tumor_sample_ID=$(awk 'NR==2{print $3}' $config_file)
  case_ID=$(echo ${Normal_sample_ID} | sed 's/_N//')
  sample_chr=$(echo "${Normal_file_ID}" | sed 's/.*\.//')
  # Run the pindel script
  echo -e "${case_ID}\tNormal_ID=${Normal_file_ID}\tTumor_ID=${Tumor_file_ID}\tStart"
  bash ${pipeline_path}/run_pindel.sh ${Normal_file_ID} ${Tumor_file_ID} ${case_ID} &
  # Run the genomonITD script for both Normal and Tumor samples
  bash ${pipeline_path}/run_genomonITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &
  # Run the ScanITD script for both Normal and Tumor samples
  bash ${pipeline_path}/run_scanITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &
  wait
  echo -e "${case_ID}\tNormal_ID=${Normal_file_ID}\tTumor_ID=${Tumor_file_ID}\tDone"
done
wait

############### run deduplicate ###############
for config_file in config/*.txt
do

done

############### run merge sample in single caller ###############
for config_file in config/*.txt
do
# Extract information from the configuration file
  Normal_file_ID=$(awk 'NR==1{print $1}' $config_file | sed 's#slicebam/##; s/.bam$//')
  Tumor_file_ID=$(awk 'NR==2{print $1}' $config_file | sed 's#slicebam/##; s/.bam$//')
  Normal_sample_ID=$(awk 'NR==1{print $3}' $config_file)
  Tumor_sample_ID=$(awk 'NR==2{print $3}' $config_file)
  case_ID=$(echo ${Normal_sample_ID} | sed 's/_N//')
  sample_chr=$(echo "${Normal_file_ID}" | sed 's/.*\.//')
  #
  echo -e "${case_ID}\tNormal_ID=${Normal_file_ID}\tTumor_ID=${Tumor_file_ID}\tStart"
  bash ${filter_path}/merge_pindel.sh ${Normal_file_ID} ${Tumor_file_ID} ${case_ID} &
  echo -e "${case_ID}\tNormal_ID=${Normal_file_ID}\tTumor_ID=${Tumor_file_ID}\tStart"
  bash ${filter_path}/merge_genomon.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &  
  echo -e "${case_ID}\tNormal_ID=${Normal_file_ID}\tTumor_ID=${Tumor_file_ID}\tStart"
  bash ${filter_path}/merge_scanITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &
done
wait