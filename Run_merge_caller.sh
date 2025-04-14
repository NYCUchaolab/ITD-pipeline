#!/bin/sh

cancer=$1
start_number=$2
end_number=$3



source $ITD_PIPELINE_CONFIG
source $TOOLS
#
eval "$(conda shell.bash hook)"
conda activate $pyITD_ENV

CANCER_DIR=${BASE_DIR}/${cancer}
echo $CANCER_DIR

# check_and_create_dir $CANCER_DIR modified_vcf


# 
for number in $(seq "$start_number" "$end_number"); do
    echo "Processing sample ${number} for cancer type ${cancer}..."
    
    echo "$pyITD_SAMPLE_SHEET_DIR/${cancer}_sample_${number}.tsv"
    echo "$CANCER_DIR/raw_data"
    echo "$CANCER_DIR/modified_vcf"

    # run merge_caller.py
    python $PIPELINE_DIR/scripts/merge_caller.py \
        -s "$pyITD_SAMPLE_SHEET_DIR/${cancer}_sample_${number}.tsv" \
        -i "$CANCER_DIR/raw_data" \
        -o "$CANCER_DIR/modified_vcf"
    # wait 180 sec
    #sleep 180
done

conda deactivate