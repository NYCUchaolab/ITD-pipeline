#!/bin/sh

set -euo pipefail

# Global Variable
BASHRC=~/.bashrc

shopt -s expand_aliases
# source $BASHRC

VERSION=0.1.2
OUT_DIR=./
SAMPLE_SHEET=unset
verbose=false

usage(){
>&2 cat << EOF
Usage: $0
   [ -V | --version ]
   [ -v | --verbose ]
   [ -h | --help ]
   [ -s | --sample_sheet  args]
   [ -o | --out_dir args; default=./ ]
EOF
}

args=$(getopt -a -o Vvhs:o: --long version,verbose,help,sample_sheet:,out_dir: -- "$@")

if [[ $? -gt 0 ]]; then
  usage
fi

eval set -- ${args}
while :
do
  case $1 in
    -V | --version)        echo $VERSION ; exit 1 ;;
    -v | --verbose)        verbose=true ; shift   ;;
    -h | --help)           wanglab_banner2 ;usage ; exit 1 ;;
    -s | --sample_sheet)   SAMPLE_SHEET=$2 ; shift 2;;
    -o | --out_dir)        OUT_DIR=$2   ; shift 2 ;;

    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    *) >&2 echo Unsupported option: $1
       usage ;;
  esac
done

gdc_download(){

        
        GDC_ID=${1}
        FILE_NAME=${2}
        TCGA_ID=${3}

        echo "start Downloading WXS BAM files"
        gdc-client download -t $GDC_TOKEN -d . $GDC_ID

        wait

        # rename file

        file_name=($(echo ${FILE_NAME} | tr "."  ' '))
        mv ${GDC_ID}/${file_name[0]}.bam ${GDC_ID}.bam
        mv ${GDC_ID}/${file_name[0]}.bai ${GDC_ID}.bai

        # clean up
        rm -r ${GDC_ID}


        echo "Done Downloading WXS BAM files"

}


if [ $verbose = true ]; then   
   wanglab_banner2
   >&2 echo "version          : ${VERSION}"
   >&2 echo "Sample Sheet     : ${SAMPLE_SHEET} "
   >&2 echo "Output Directory : ${OUT_DIR}"
fi

# checking file existence
[[ ! -f $SAMPLE_SHEET ]] && {
        echo "$SAMPLE_SHEET does not exist"
        exit 1
}

# reading sample sheet
tail -n +2 $SAMPLE_SHEET | while IFS=$',' read -r -a sample
do
        # [0]: file ID
        # [1]: file name
        # [6]: sample ID

        gdc_download ${sample[0]} ${sample[1]} ${sample[6]}
done
