#!/bin/sh

cancer=$1
start_number=$2
end_number=$3


for number in $(seq $start_number $end_number); do
    
    # run ITD_pipeline_v3_1.sh
    bash ~/ITD-pipeline/scripts/check_sample.sh \
        -d ~/TCGA_sliced/result/$cancer \
        -s ~/TCGA_sliced/${cancer}_samplesheet/${cancer}_sample_${number}.tsv
done
