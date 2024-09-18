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
    - `filter_genomonITD.sh`
    - `filter_pindel.sh`
    - `filter_scanITD.sh`
5. Merge ITDs from all chromosomes within the same sample for each caller
    - `merge_genomonITD.sh`
    - `merge_pindel.sh`
    - `merge_scanITD.sh`
    - For tumor/normal comparison:
       - `merge_genomonITD_TN.sh`
       - `merge_scanITD_TN.sh`
         
6. Combine the ITD results from all three callers into a final output:
     - `merge_all_caller.sh`

## Calling
### run_genomonITD.sh
**Required Files:**
   - `hg38.refGene.gtf` (2020)
   - `hg38.knowGene.gtf` (2023)
   - `hg38.ensGene.gtf` (2020)
   - `simpleRepeat.txt` (2022)

**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Execute Genomon-ITDetecter via `detectITD.sh`.
3. Store results in directories organized by File ID and chromosome.

### run_pindel.sh
**Required Files:**
   - `parameters.config`
   - `somatic_indelfilter.pl` (Pindel's T/N filtering script)
   - `somatic.indel.filter.config`

**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Execute Pindel for ITD detection.
3. Apply `somatic_indelfilter.pl` to filter somatic indels.
4. Store results in directories organized by Case ID and chromosome.

### run_scanITD.sh
**Required Files:**
   - `gencode.v36.annotation.gtf` (divided into 23 chromosomes)

**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Execute ScanITD using `ScanITD.py`.
3. Store results in directories organized by File ID and chromosome.

## Filtering and Deduplication:

### filter_genomonITD.sh
**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Filter ITDs within length range 3 to 300 base pairs.
3. Deduplicate ITDs sharing the same Sample ID.

### filter_pindel.sh
**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Filter ITDs within length range 3 to 300 base pairs.
3. Deduplicate ITDs sharing the same Case ID.

### filter_scanITD.sh
**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Filter ITDs within length range 3 to 300 base pairs.
3. Deduplicate ITDs sharing the same Sample ID.

## Merging ITD Results:

### merge_genomonITD.sh
**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Merge results for ITDs sharing the same Sample ID.
3. Compare and merge results for ITDs sharing the same Case ID.

### merge_pindel.sh
**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Merge results for ITDs sharing the same Sample ID.

### erge_scanITD.sh
**Workflow:**
1. Read configuration parameters from `parameters.config`.
2. Merge results for ITDs sharing the same Sample ID.

### merge_genomonITD_TN.sh
**Workflow:**
1. Compare and merge tumor/normal ITD files for the same Case ID.

### merge_scanITD_TN.sh
**Workflow:**
1. Compare and merge tumor/normal ITD files for the same Case ID.

### merge_all_caller.sh
**Workflow:**
1. Output an ITD if it is detected by at least two of the three ITD callers (GenomonITD, Pindel, ScanITD).
