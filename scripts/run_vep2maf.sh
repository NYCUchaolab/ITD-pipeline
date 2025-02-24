#!/bin/sh

cd /home/data/data_Jeffery/veptest/vep113_test/

perl vcf2maf.pl \
      --input-vcf 1ca9c5b4-66d2-4266-ba19-f2709c7cc25e.sorted.vcf \
      --output-maf 1ca9c5b4-66d2-4266-ba19-f2709c7cc25e.sorted.113pl.maf \
      --normal-id TCGA-14-0813_N \
      --tumor-id TCGA-14-0813_T \
      --ref-fasta /home/data/data_Jeffery/ITD-detection/GenomonITDetector38/GRCh38.d1.vd1.fa \
      --vep-data /home/data/database/vep/ \
      --vep-path /home/Jeffery/miniconda3/envs/vep_113/share/ensembl-vep-113.2-0/ \
      --ncbi-build GRCh38 \
      --cache-version 113 \
      --vep-overwrite \
      > 1ca9c5b4-66d2-4266-ba19-f2709c7cc25e_vcf2maf.log 2>&1

#perl vcf2maf.pl --input-vcf tests/test.vcf --output-maf tests/test.vep.maf
