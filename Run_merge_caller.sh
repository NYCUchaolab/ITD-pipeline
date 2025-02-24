#!/bin/sh

#
start_number=1
end_number=678
cancer="GBM"

#
source $ITD_PIPELINE_CONFIG

#
eval "$(conda shell.bash hook)"
conda activate $vep113_ENV

#
base_dir="/staging/biology/u4583512/TCGA_whole/${cancer}/modified_vcf"
mkdir -p "$base_dir/genomonITD" "$base_dir/pindel" "$base_dir/scanITD" "$base_dir/merge_caller"

# 
for number in $(seq "$start_number" "$end_number"); do
    echo "Processing sample ${number} for cancer type ${cancer}..."
    
    # run merge_caller.py
    python scripts/merge_caller.py \
        -s "/staging/biology/u4583512/TCGA_whole/slice_sample_sheet/${cancer}/${cancer}_sample_${number}.tsv" \
        -i "/staging/biology/u4583512/TCGA_whole/${cancer}/raw_data" \
        -o "$base_dir"

    # wait 180 sec
    #sleep 180
done

conda deactivate