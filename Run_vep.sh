#!/bin/sh

#
start_number=1
end_number=5
cancer="GBM"

#
eval "$(conda shell.bash hook)"
conda activate vep113

#
input_dir="/staging/biology/u4583512/TCGA_whole/${cancer}/modified_vcf/merge_caller"
output_dir="/staging/biology/u4583512/TCGA_whole/${cancer}/vep_result"

mkdir -p "$output_dir"  "$output_dir/split_vcf" "$output_dir/vep_vcf" "$output_dir/vep_maf"

#
ref="/home/u4583512/ITD-pipeline-3.12/tools/GenomonITDetector38/GRCh38.d1.vd1.fa"
vep_data="/staging/biology/u4583512/"
vep_path="/home/u4583512/miniconda3/envs/vep113/share/ensembl-vep-113.2-0/"

#
vcf_files=($(ls "$input_dir"/*.vcf))
if [ ${#vcf_files[@]} -eq 0 ]; then
    echo "Error: No VCF files found in $input_dir"
    exit 1
fi

#
for number in $(seq "$start_number" "$end_number"); do
    case_id=$(basename "${vcf_files[$((number-1))]}" .vcf)

    echo "Processing sample ${number} (${case_id}) for cancer type ${cancer}..."

    # run vcf2maf.pl
    perl scripts/vcf2maf.pl \
        --input-vcf "${input_dir}/${case_id}.vcf" \
        --output-maf "${output_dir}/vep_maf/${case_id}.maf" \
        --normal-id "${case_id}_N" \
        --tumor-id "${case_id}_T" \
        --ref-fasta "$ref" \
        --vep-data "$vep_data" \
        --vep-path "$vep_path" \
        --ncbi-build GRCh38 \
        --cache-version 113 \
        --vep-overwrite
        
    #move file
    if [ -f "${input_dir}/${case_id}.vep.vcf" ]; then
        mv "${input_dir}/${case_id}.vep.vcf" "$output_dir/vep_vcf/"
    fi
    
    if [ -f "${input_dir}/${case_id}.split.vcf" ]; then
        mv "${input_dir}/${case_id}.split.vcf" "$output_dir/split_vcf/"
    fi
    
done
conda deactivate