#!/bin/sh


start_number=1
end_number=3
cancer="ACC"


for number in $(seq $start_number $end_number); do
    echo "Processing sample ${number} for cancer type ${cancer}..."
    
    # run ITD_pipeline_v3_1.sh
    bash ITD_pipeline_v3_1.sh -v 1 \
        -s "/staging/biology/u4583512/TCGA_slice/slice_sample_sheet/${cancer}/${cancer}_sample_${number}.tsv" \
        -i "/staging/biology/u4583512/TCGA_cancer_census_bam/${cancer}" \
        -o "/staging/biology/u4583512/TCGA_slice/${cancer}"

    # wait 30 sec
    sleep 30
done
