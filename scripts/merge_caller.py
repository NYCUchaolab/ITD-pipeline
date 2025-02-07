import sys
import os

# Determine the absolute path to the 'tools' directory
current_dir = os.path.dirname(os.path.abspath(__file__))
tools_path = os.path.join(current_dir, '..', 'tools')

# Add the 'tools' directory to sys.path
if tools_path not in sys.path:
    sys.path.insert(0, tools_path)



from pyITD.utility import read_sample_info
from pyITD.ITD_DataFrame import ITD_DataFrame
from pyITD.genomonITD import GenomonITD
from pyITD.pindelITD import PindelITD
from pyITD.scanITD import ScanITD
from pyITD.pyITD import TrioITD
import os
#!/usr/bin/env python3
"""
Script to process a sample sheet and manage input/output directories.

This script accepts a mandatory sample sheet file and optional input/output directory paths.
It is intended as a template for processing sample sheets in bioinformatics or similar workflows.
"""

import argparse

def ensure_dir(dir: str) -> bool:
    """
    Check if a directory exists, and create it if it does not.

    Args:
        directory (str): The path of the directory to check or create.
    """
    if not os.path.exists(dir):
        os.makedirs(dir)
        print(f"Directory '{dir}' created.")
    else:
        print(f"Directory '{dir}' already exists.")

def check_file_exists(filepath: str) -> bool:
    """
    Check if a file exists at the given path.

    Args:
        filepath (str): The path to the file.

    Returns:
        bool: True if the file exists, False otherwise.
    """
    return os.path.isfile(filepath)

def count_vcf_files(directory: str, case_id: str) -> int:
    """
    Count the number of VCF files matching the pattern 'ZZZ*.vcf' in the given directory.

    Args:
        directory (str): The directory path where VCF files should be checked.

    Returns:
        int: The number of matching VCF files.

    Raises:
        FileNotFoundError: If the directory does not exist.
    """
    if not os.path.isdir(directory):
        raise FileNotFoundError(f"Directory '{directory}' does not exist.")

    count = sum(1 for file in os.listdir(directory) if file.startswith(case_id) and file.endswith(".vcf"))
    # print(count)
    return count

def caller_type(ITD_df: ITD_DataFrame) -> tuple[str]:
    if isinstance(ITD_df, PindelITD):
        return 'pindel', 'pindel' 
    elif isinstance(ITD_df, ScanITD):
        return 'scanITD', 'scanITD' 
    elif isinstance(ITD_df, GenomonITD):
        return 'genomonITD', 'genomonITD'
    elif isinstance(ITD_df, TrioITD):
        return 'merge_caller', 'merge'
    else:
        raise TypeError("ITD_df must be an instance of PindelITD, ScanITD, GenomonITD or TrioITD")

def write_caller(ITD_df: ITD_DataFrame, output_dir: str, case_id: str):
    # ITD caller type
    caller, postfix = caller_type(ITD_df)

    ensure_dir(f"{output_dir}/{caller}")
    
    out_file_prefix = f"{output_dir}/{caller}/{case_id}"

    vcf_count = count_vcf_files(f"{output_dir}/{caller}", case_id)
    if vcf_count > 0: # more than 1 vcf exist(s)
        if caller == "merge_caller":
            # read existed vcf
            ITD_df2 = TrioITD.read_ITD_vcf(f"{output_dir}/{caller}/{case_id}.{postfix}.vcf")
            ITD_df = TrioITD.concat([ITD_df, ITD_df2]).sorting().deduplicate(chromosome_wise=True, multi_proc=True)
            ITD_df.to_vcf(f"{out_file_prefix}.{postfix}.vcf")
            print(f"write merged caller VCF at {out_file_prefix}.{postfix}.vcf")
        else:
            ITD_df.to_vcf(f"{out_file_prefix}_{vcf_count}.{postfix}.vcf")
            print(f"write {caller} VCF at {out_file_prefix}_{vcf_count}.{postfix}.vcf")

    else:
        ITD_df.to_vcf(f"{out_file_prefix}.{postfix}.vcf")
        print(f"write {caller} VCF at {out_file_prefix}.{postfix}.vcf")

        

def write_merge_caller(ITD_df: TrioITD, output_dir: str, case_id: str):
    if not isinstance(ITD_df, TrioITD):
        raise TypeError("ITD_df must be an instance of TrioITD")

    ensure_dir(f"{output_dir}/merge_caller")
    out_file_prefix = f"{output_dir}/merge_caller/{case_id}.merged"
    if check_file_exists(f"{out_file_prefix}.vcf"):
        pass
    else:
        ITD_df.to_vcf(f"{out_file_prefix}.vcf")



def get_parser():
    """
    Create and return the argument parser for this script.

    Returns:
        argparse.ArgumentParser: The configured argument parser.
    """
    parser = argparse.ArgumentParser(
        description="Process a sample sheet and manage input/output directories."
    )
    parser.add_argument(
        "--samplesheet", "-s", type=str,
        help="Path to the sample sheet file.",
        required=True
    )
    parser.add_argument(
        "--input_dir", "-i", type=str,
        help="Path to the input directory (default is current directory).",
        default=".", required=False
    )
    parser.add_argument(
        "--output_dir", "-o", type=str,
        help="Path to the output directory (default is current directory).",
        default=".", required=False
    )
    return parser

if __name__ == '__main__':
    parser = get_parser()
    args = parser.parse_args()

    # Example functionality: print the provided arguments.
    print("Samplesheet:", args.samplesheet)
    print("Input Directory:", args.input_dir)
    print("Output Directory:", args.output_dir)

    #TODO:
    # [√] read sample sheet
    # [√] read pindel
    # [√] read scanITD
    # [√] read genomonITD
    # [√] merge caller
    # [√] save each caller (4)
    #   [√] check if the file was existed
    #   [√] add _# for the individual caller and save it 
    #   [√] read the existed merged caller vcf, and intersect with this
    #   [√] overwrite the existed merged caller vcf

    sample_info = read_sample_info(args.samplesheet) # Case ID, Tumor ID, Normla ID
    input_dir = args.input_dir
    out_dir = args.output_dir

    case_id = sample_info["Case ID"]

    scanITD_df = ScanITD.read_paired_sample(f'{input_dir}/scanITD', sample_info)
    pindelITD_df = PindelITD.read_paired_sample(f'{input_dir}/pindel', sample_info)
    genomonITD_df = GenomonITD.read_paired_sample(f'{input_dir}/genomonITD', sample_info)

    trio_ITD = TrioITD.merge_3_caller(scanITD_df, pindelITD_df, genomonITD_df).sorting()
    # check directory existence else create
    # each write
    
    ###### pindel #######
    
    # check directory existence
    write_caller(pindelITD_df, out_dir, case_id)
    write_caller(scanITD_df, out_dir, case_id)
    write_caller(genomonITD_df, out_dir, case_id)
    write_merge_caller(trio_ITD, out_dir, case_id)
