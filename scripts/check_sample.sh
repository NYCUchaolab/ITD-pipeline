#!/bin/sh
set -euo pipefail

# Global Variable
BASHRC=~/.bashrc

shopt -s expand_aliases
# source $BASHRC
source $ITD_PIPELINE_CONFIG
source $BANNER_SH
source $TOOLS
source $READ_SAMPLE_SHEET

VERSION=0.1.2
VERBOSE=0

eval "$(conda shell.bash hook)"

usage(){
>&2 cat << EOF
Usage: $0
   [ -V | --version ]
   [ -v | --verbose args; default=0 ]
   [ -h | --help ]
   [ -s | --sample_sheet args ]
   [ -d | --directory args ]


EOF
}

args=$(getopt -a -o Vv:hs:d: --long version,verbose:,help,sample_sheet:,directory: -- "$@")

if [[ $? -gt 0 ]]; then
  usage
fi

eval set -- ${args}

while :
do
  case $1 in
    -V | --version)        echo $VERSION ; exit 1 ;;
    -v | --verbose)        VERBOSE=$2 ; shift 2 ;;
    -h | --help)           usage ; exit 1 ;;
    -s | --sample_sheet)   SAMPLE_SHEET=$2 ; shift 2;;
    -d | --directory)      DIRECTORY=$2 ; shift 2 ;;

    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    *) >&2 echo Unsupported option: $1
       usage 
       exit 1;;
  esac
done

: << 'TODO_LIST'
1. [X] read the sample sheet 
2. [X] check pindel: 
    [X] |-> read pindel chrom ...
    [X] |-> pair sample_dir existence
    [X] |-> p1 existence
    [X] |-> p2 existence
3. [ ] check scanITD:
    [X] |-> directory existence
    [X] |-> T/N all partition existence

4. [X] genomon-ITDetector 
    [X] |-> directory existence
    [X] |-> T/N itd.tsv existence
TODO_LIST

parse_sample_sheet $SAMPLE_SHEET
check_variables_set Case_ID Tumor_fileID Normal_fileID Tumor_fileID

# check pindel 
declare -a pindel_partition

check_dir_existence2 "Pindel: ${Tumor_fileID} - ${Normal_fileID}" $DIRECTORY/raw_data/pindel/${Tumor_fileID}_${Normal_fileID}

for partition in $(awk -F= '{print $1}' $PINDEL_SLICE_CHROM); do
    check_file_existence2 "Pindel: $partition result" $DIRECTORY/raw_data/pindel/${Tumor_fileID}_${Normal_fileID}/$partition/indel.filter.output
done

# check scanITD
check_dir_existence2 "ScanITD: ${Tumor_fileID}" $DIRECTORY/raw_data/scanITD/${Tumor_fileID}
check_dir_existence2 "ScanITD: ${Normal_fileID}" $DIRECTORY/raw_data/scanITD/${Normal_fileID}

declare -a scanITD_partition

for partition in $(awk -F= '{print $1}' $SCANITD_SLICE_CHROM); do
    check_file_existence2 "ScanITD: $Tumor_fileID $partition result" $DIRECTORY/raw_data/scanITD/${Tumor_fileID}/$partition.itd.vcf
    check_file_existence2 "ScanITD: $Normal_fileID $partition result" $DIRECTORY/raw_data/scanITD/${Normal_fileID}/$partition.itd.vcf
done

check_dir_existence2 "GenomonITD: ${Tumor_fileID}" $DIRECTORY/raw_data/genomonITD/${Tumor_fileID}
check_dir_existence2 "GenomonITD: ${Normal_fileID}" $DIRECTORY/raw_data/genomonITD/${Normal_fileID}

check_file_existence2 "GenomonITD: $Tumor_fileID result" $DIRECTORY/raw_data/genomonITD/${Tumor_fileID}/itd_list.tsv
check_file_existence2 "GenomonITD: $Normal_fileID result" $DIRECTORY/raw_data/genomonITD/${Normal_fileID}/itd_list.tsv

log 1 "$Tumor_fileID Successed"
log 1 "$Normal_fileID Successed" 
log 1 ""
