# ITD Pipeline
<img width="1031" src="https://github.com/Juan-Jeffery/ITD-pipeline/blob/main/ITD-pipeline.png" width="1000" height="265">

---

# ITD Pipeline

A comprehensive pipeline for detecting and analyzing Internal Tandem Duplications (ITDs) across cancer samples. This pipeline integrates multiple tools and supports batch processing for large datasets from GDC.

## 📦 Installation

### Clone the Repository
```bash
git clone https://github.com/NYCUchaolab/ITD-pipeline.git
```

### Set Configuration Path
Add the following line to your `~/.bashrc` or `~/.bash_aliases`, and then reload your shell:
```bash
export ITD_PIPELINE_CONFIG="/home/user/ITD_pipeline/config/ITD_pipeline.config"
```

### Create Conda Environments
```bash
conda create -n master-genomonITD --file /home/user/ITD-pipeline/config/genomonITD.txt
conda create -n master-pindel --file /home/user/ITD-pipeline/config/pindel.txt
conda create -n master-scanITD --file /home/user/ITD-pipeline/config/scanITD.txt
conda create -n master-pyITD --file /home/user/ITD-pipeline/config/pyITD.txt
conda create -n master-vep113 --file /home/user/ITD-pipeline/config/vep113.txt
```

### Set Folder Permissions
Ensure all working folders have appropriate permissions:
```bash
chmod -R 755 /path/to/your/folders
```

### Update Configuration Files
Manually configure the following files as needed:
- `database/somatic.indel.filter.config`
- `config/itd_pipeline.config`
- `config/config.env`

### Gmail Notification Setup *(Optional)*
Update Gmail settings in your script if email notifications are required.

## 🚀 Usage

### 1. Split Sample Sheet
Split the GDC sample sheet into T/N pair:
```bash
bash utility/split_sample_sheet.sh OV_gdc_sample_sheet.tsv OV
```

### 2. Run ITD Pipeline
Execute the ITD pipeline for a specified range of samples:
```bash
bash Run_pipeline.sh OV <start_sample_number> <end_sample_number>
```

### 3. Merge Callers
Combine results from different ITD detection tools:
```bash
bash Run_merge_caller.sh OV <start_sample_number> <end_sample_number>
```

### 4. Run VEP Annotation (v113)
Run Variant Effect Predictor (VEP) for annotation:
```bash
bash Run_vep.sh OV <start_sample_number> <end_sample_number>
```

## ⚠️ Notes

- **Avoid long folder names**, as they may cause issues with `Genomon`.
- **Tumor-only mode:**  
  To analyze tumor-only data:
  1. Modify the `pindel` Perl script to disable TN filtering.
  2. Edit `merge_caller.py` to remove TN filters.

## 📥 GDC Data Download

Update the token path inside `GDC_download.sh`.
```bash
bash GDC_download.sh -s gdc_sample_sheet.2024-12-14.tsv -o output_dir/
```

## 🔎 Error Checking

Use the batch check script to identify failed samples:
```bash
bash batch_check_sample.sh OV 1 50
```

## 🧩 Merge Sample Sheets

If the sample sheet is split (e.g., for TN pairing), merge them before downloading data:
```bash
bash merge_sample_sheet.sh GBM 1 50 "split_sample_sheet_dir" "1_50.tsv"
```

## 📄 License

MIT License © NYCU Chao Lab
   
