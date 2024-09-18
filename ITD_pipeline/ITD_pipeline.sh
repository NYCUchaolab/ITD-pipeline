#!/bin/sh

# Source the parameters from the config file
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

cd ${cwd}
############### slice bam ###############
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tSlice_bam.sh Start"
#bash ${pipeline_path}/Slice_bam.sh
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tSlice_bam.sh Done"

############### make config ###############
Normal_sample_sheet=$1
Tumor_sample_sheet=$2

echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tMake_config.sh Start"
bash ${pipeline_path}/Make_config.sh ${Tumor_sample_sheet} ${Normal_sample_sheet}
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tMake_config.sh Done"

############### run all caller ###############
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tCalling Start"
# 砞﹚程︽穨计秖
MAX_JOBS=14
job_count=0
for config_file in config/*.txt
do
  # Extract information from the configuration file
  Normal_file_ID=$(awk 'NR==1{print $1}' $config_file | sed 's#slicebam/##; s/.bam$//')
  Tumor_file_ID=$(awk 'NR==2{print $1}' $config_file | sed 's#slicebam/##; s/.bam$//')
  Normal_sample_ID=$(awk 'NR==1{print $3}' $config_file)
  Tumor_sample_ID=$(awk 'NR==2{print $3}' $config_file)
  case_ID=$(echo ${Normal_sample_ID} | sed 's/_N//')
  sample_chr=$(echo "${Normal_file_ID}" | sed 's/.*\.//')

  # 秨﹍磅︽3穨
  bash ${pipeline_path}/run_pindel.sh ${Normal_file_ID} ${Tumor_file_ID} ${case_ID} &
  bash ${pipeline_path}/run_genomonITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &
  bash ${pipeline_path}/run_scanITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &

  # 糤穨计秖
  ((job_count++))
  
  # 讽笷程穨计秖单┮Τ穨ЧΘ
  if [ $job_count -ge $MAX_JOBS ]; then
    wait
    job_count=0  # 竚穨璸计竟
  fi
done
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tCalling Done"
############### run filter ###############
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tfilter Start"
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
  bash ${filter_path}/filter_pindel.sh ${Normal_file_ID} ${Tumor_file_ID} ${case_ID} &
  #
  bash ${filter_path}/filter_genomonITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &  
  #
  bash ${filter_path}/filter_scanITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &
done
wait
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tfilter Done"

############### run merge ###############
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tmerge Start"
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
  bash ${filter_path}/merge_pindel.sh ${Normal_file_ID} ${Tumor_file_ID} ${case_ID} &
  #
  bash ${filter_path}/merge_genomonITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &  
  #
  bash ${filter_path}/merge_scanITD.sh ${Normal_file_ID} ${Tumor_file_ID} ${Normal_sample_ID} ${Tumor_sample_ID} &
done
wait
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tmerge Down"

############### run merge sample in single caller TN ###############
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tmerge TN Start"
for genomonITD_Tumor_file in genomon_ITD/*_T.itd.filter.de.tsv
do
  case_ID=$(basename ${genomonITD_Tumor_file} "_T.itd.filter.de.tsv")
  Normal_sample_file="genomon_ITD/${case_ID}_N.itd.filter.de.tsv"
  Tumor_sample_file="${genomonITD_Tumor_file}"
  #
  bash ${filter_path}/merge_genomonITD_TN.sh ${Normal_sample_file} ${Tumor_sample_file} ${case_ID} &
done
for scanITD_Tumor_file in scanITD/*_T.itd.filter.de.tsv
do
  case_ID=$(basename ${scanITD_Tumor_file} "_T.itd.filter.de.tsv")
  Normal_sample_file="scanITD/${case_ID}_N.itd.filter.de.tsv"
  Tumor_sample_file="${scanITD_Tumor_file}"
  #
  bash ${filter_path}/merge_scanITD_TN.sh ${Normal_sample_file} ${Tumor_sample_file} ${case_ID} &
done
wait
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\tmerge TN Done"

############### run merge sample in all caller ###############
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t 3-2 caller Start"
cd ${cwd}
for genomonITD_Tumor_file in /genomon_ITD/*_T.itd.filter.de.tsv
do
  case_ID=$(basename ${genomonITD_Tumor_file} "_T.itd.filter.de.tsv")
  #
  #bash ${filter_path}/merge_all_caller.sh ${case_ID} &
done
wait
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t 3-2 caller Done"