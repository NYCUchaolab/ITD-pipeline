#!/bin/sh

#
start_number=$1
end_number=$2
cancer=$3

#
source $ITD_PIPELINE_CONFIG
source $TOOLS
source $READ_SAMPLE_SHEET
#
eval "$(conda shell.bash hook)"
conda activate $vep113_ENV

VERBOSE=1
BASE_DIR=/staging/biology/u4583512/TCGA_slice
pyITD_SAMPLE_SHEET_DIR=/staging/biology/u4583512/TCGA_slice/slice_sample_sheet/${cancer}
INPUT_DIR=$BASE_DIR/${cancer}/modified_vcf/merge_caller
OUTPUT_DIR=$BASE_DIR/${cancer}/vep

mkdir -p "$OUTPUT_DIR"  "$OUTPUT_DIR/split_vcf" "$OUTPUT_DIR/vep_vcf" "$OUTPUT_DIR/vep_maf"

#
for number in $(seq "$start_number" "$end_number"); do
    parse_sample_sheet_vep $pyITD_SAMPLE_SHEET_DIR/${cancer}_sample_${number}.tsv
    
    # case_id=$(basename "${vcf_files[$((number-1))]}" .vcf)
    check_file_existence "${Case_ID} vcf" $INPUT_DIR/${Case_ID}.merged.vcf
    echo "Processing sample ${number} (${Case_ID}) for cancer type ${cancer}..."
    echo "${INPUT_DIR}/${Case_ID}.merged.vcf"
    
    # run vcf2maf.pl
    perl $PIPELINE_DIR/scripts/vcf2maf.pl \
        --input-vcf "${INPUT_DIR}/${Case_ID}.merged.vcf" \
        --output-maf "${OUTPUT_DIR}/vep_maf/${Case_ID}.merged.vep113.maf" \
        --normal-id "${Case_ID}_N" \
        --tumor-id "${Case_ID}_T" \
        --ref-fasta $vep113_REF \
        --vep-data $vep113_DATA \
        --vep-path $vep113_PATH \
        --ncbi-build GRCh38 \
        --cache-version 113 \
        --vep-overwrite 

        
    #move file
    if [ -f "${INPUT_DIR}/${Case_ID}.merged.vep.vcf" ]; then
        mv "${INPUT_DIR}/${Case_ID}.merged.vep.vcf" "$OUTPUT_DIR/vep_vcf/"
    fi
    
    if [ -f "${INPUT_DIR}/${Case_ID}.merged.split.vcf" ]; then
        mv "${INPUT_DIR}/${Case_ID}.merged.vep113.split.vcf" "$OUTPUT_DIR/split_vcf/"
    fi
    
done

conda deactivate