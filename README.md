# ITD Pipeline
<img src="https://github.com/NYCUchaolab/ITD-pipeline/blob/main/ITD-pipeline.png" width="1000" height="275">


## ITD_pipeline.sh
1. Slice BAM files by chromosome using `Slice_bam.sh` (Chromosomes 1, 2, 3, and 7 will be further divided into p and q arms)
2. Create tumor/normal pair configurations by sample using `Make_config.sh`
3. Run three ITD detection tools by reading the configuration:
    - `run_genomonITD.sh`
    - `run_pindel.sh`
    - `run_ScanITD.sh`
4. Deduplicate & Filter ITDs
5. Merge ITDs from all chromosomes within the same sample for each caller
6. Merge results from all three callers

## run_genomonITD.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Execute Genomon-ITDetecter (`detectITD.sh`)
3. Store files in separate directories by File ID and chromosome

## run_pindel.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Execute Pindel
3. Run `somatic_indelfilter.pl` (pindel's T/N filtering script, requires `somatic.indel.filter.config`)
4. Store files in separate directories by Case ID and chromosome

## run_ScanITD.sh
1. Read `parameters.config` (which includes basic paths and parameters)
2. Execute ScanITD (`ScanITD.py`)
3. Store files in separate directories by File ID and chromosome
