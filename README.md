# ITD Pipeline
<img src="https://github.com/NYCUchaolab/ITD-pipeline/blob/main/ITD-pipeline.png" width="1000" height="265">


## ITD_pipeline.sh
1. Slice BAM files by chromosome using `Slice_bam.sh` (Chromosomes 1, 2, 3, and 7 will be further divided into p and q arms)
2. Create tumor/normal pair configurations by sample using `Make_config.sh`
3. Run three ITD detection tools by reading the configuration:
    - `run_genomonITD.sh`
    - `run_pindel.sh`
    - `run_ScanITD.sh`
4. Deduplicate & Filter ITDs
5. Merge ITDs from all chromosomes within the same sample for each caller
    - `merge_genomonITD.sh`
    - `merge_pindel.sh`
    - `merge_scanITD.sh`
7. Concat results from all three callers
### run_genomonITD.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Execute Genomon-ITDetecter (`detectITD.sh`)
3. Store files in separate directories by File ID and chromosome
### run_pindel.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Execute Pindel
3. Run `somatic_indelfilter.pl` (pindel's T/N filtering script, requires `somatic.indel.filter.config`)
4. Store files in separate directories by Case ID and chromosome
### run_scanITD.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Execute ScanITD (`ScanITD.py`)
3. Store files in separate directories by File ID and chromosome
### merge_genomonITD.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Merge files that share the same Sample ID
### merge_pindel.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Merge files that share the same Case ID
### merge_scanITD.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Merge files that share the same Sample ID
