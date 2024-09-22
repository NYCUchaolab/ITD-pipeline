#!/bin/sh

# Source the parameters from the config file
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

cd ${cwd}
############### run merge sample in all caller ###############
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t 3-2 caller Start"
cd ${cwd}
for genomonITD_Tumor_file in genomon_ITD/*_T.itd.filter.de.tsv
do
  case_ID=$(basename ${genomonITD_Tumor_file} "_T.itd.filter.de.tsv")
  #
  bash ${filter_path}/merge_all_caller.sh ${case_ID} 
done
wait
echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t 3-2 caller Done"