#!/bin/sh

# Source the parameters from the config file
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

cd ${cwd}
############### slice bam ###############
echo "$(date '+%Y-%m-%d %H:%M:%S') Slice_bam.sh Start"
#bash ${pipeline_path}/Slice_bam.sh
echo "Slice_bam.sh Done"

