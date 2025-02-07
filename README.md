# ITD Pipeline
<img width="1031" src="https://github.com/Juan-Jeffery/ITD-pipeline/blob/main/ITD-pipeline.png" width="1000" height="265">

---

### Install
1. Clone the repository and create the output folder:
    ```bash
    git clone https://github.com/NYCUchaolab/ITD-pipeline.git
    ```
2. Add the following command to your `~/.bashrc` or `~/.bash_aliases`, and update the bash configuration using `source ~/.bashrc`:
    ```bash
    export ITD_PIPELINE_CONFIG="/home/user/ITD_pipeline_v3_1/config/ITD_pipeline.config"
    ```
3. Create environments:
    ```bash
    conda create -n master-genomonITD --file /home/user/ITD-pipeline/config/genomonITD.txt
    conda create -n master-pindel --file /home/user/ITD-pipeline/config/pindel.txt
    conda create -n master-scanITD --file /home/user/ITD-pipeline/config/scanITD.txt
    ```
4. Ensure all folders have permissions set to `755`:
    ```bash
    chmod -R 755 /path/to/your/folders
    ```
5. Update the following configuration files as needed:
    - `database/somatic.indel.filter.config`
    - `config/itd_pipeline.config`
    - `config.env`
6. Update Gmail settings for the tools as required.

### Run
#### samplesheet_splicing
1. Run the sample sheet splitting script (update folder paths as needed):
    ```bash
    utility/split_sample_sheet.sh OVCA_gdc_sample_sheet.2019-07-01.tsv OVCA
    ```
#### run_ITD_pipeline
- Use the following commands to run the pipeline:
    ```bash
    bash Run_pipeline.sh <parameters>
    ```
    Or run in the background with logging:

    ```bash
    nohup bash Run_pipeline.sh > output.log 2>&1 &
    ```
### Notes
- Folder names should not be too long to avoid issues with Genomon.
### Other
#### GDC Install
1. Update the token path in `GDC_download.sh`.
2. Run the script:
    ```bash
    bash GDC_download.sh -s gdc_sample_sheet.2024-12-14.tsv -o output_dir/
    ```
#### Check for Errors
- Use the batch checking script:
    ```bash
    bash batch_check_sample.sh OV 1 50
    ```
#### Merge Sample Sheets
- When the sample sheet is too large and needs to be split into TN pairs, merge the files before performing the GDC download.
    ```bash
    bash merge_sample_sheet.sh GBM 1 50 "split_sample_sheet_dir" "output_file_name (e.g., 1_50.tsv)"
    ```


    
