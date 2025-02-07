#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Global Variables
BASHRC=~/.bashrc

shopt -s expand_aliases
# source $BASHRC

VERSION=0.1.2
OUT_DIR=./
SAMPLE_SHEET=unset
verbose=false

usage() {
  >&2 cat << EOF
Usage: $0
   [ -V | --version ]
   [ -v | --verbose ]
   [ -h | --help ]
   [ -s | --sample_sheet args ]
   [ -o | --out_dir args; default=./ ]
EOF
}

args=$(getopt -a -o Vvhs:o: --long version,verbose,help,sample_sheet:,out_dir: -- "$@")

if [[ $? -gt 0 ]]; then
  usage
  exit 1
fi

eval set -- ${args}
while :
do
  case $1 in
    -V | --version)        echo $VERSION ; exit 0 ;;
    -v | --verbose)        verbose=true ; shift ;;
    -h | --help)           usage ; exit 0 ;;
    -s | --sample_sheet)   SAMPLE_SHEET=$2 ; shift 2 ;;
    -o | --out_dir)        OUT_DIR=$2 ; shift 2 ;;
    --) shift ; break ;;
    *) >&2 echo "Unsupported option: $1" ; usage ; exit 1 ;;
  esac
done

if [ "$verbose" = true ]; then
  echo "Version          : ${VERSION}"
  echo "Sample Sheet     : ${SAMPLE_SHEET}"
  echo "Output Directory : ${OUT_DIR}"
fi

# Check if SAMPLE_SHEET exists
if [[ ! -f "$SAMPLE_SHEET" ]]; then
  echo "Error: $SAMPLE_SHEET does not exist."
  exit 1
fi

# Ensure output directory exists
mkdir -p "$OUT_DIR"

# Function to download files using gdc-client
gdc_download() {
  GDC_TOKEN=./database/gdc-user-token.2024-12-09T06_41_36.514Z.txt
  file_id=${1}
  file_name=${2}
  sample_id=${3}

  echo "Starting download for file_id: $file_id"
  gdc-client download -t "$GDC_TOKEN" -d "$OUT_DIR" "$file_id"

  # Rename files
  local file_basename=$(echo "$file_name" | cut -d. -f1)
  mv "$OUT_DIR/$file_id/$file_basename.bam" "$OUT_DIR/$file_id.bam"
  mv "$OUT_DIR/$file_id/$file_basename.bai" "$OUT_DIR/$file_id.bai"

  # Clean up directory
  rm -r "$OUT_DIR/$file_id"

  echo "Done downloading file_id: $file_id"
}

# Process the sample sheet
echo "Reading sample sheet: $SAMPLE_SHEET"
tail -n +2 "$SAMPLE_SHEET" | while IFS=$',' read -r -a sample
  do
    gdc_download "${sample[0]}" "${sample[1]}" "${sample[6]}"
done

echo "All downloads completed successfully."
