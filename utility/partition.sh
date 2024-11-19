#!/bin/sh

slice_bam(){
  local OUT_DIR=$1
  local FILE=$2;
  local SLICE_CHROM_DB=$3
  local -A CHROM_NAME_ORD_ARR
  local FILE_NAME=$(basename "$FILE" .bam)
  
  conda activate $SAMTOOLS_ENV  

  log 1 "Reading BAM slicing partition information in ${SLICE_CHROM_DB}..."
  while IFS="=" read -r key value; do
      CHROM_NAME_ORD_ARR["$key"]="$value"
      log 1 "partition ${key}: ${value}"
  done < $SLICE_CHROM_DB

  for CHROM_NAME in "${!CHROM_NAME_ORD_ARR[@]}"; do
    local CHROM=${CHROM_NAME_ORD_ARR[$CHROM_NAME]}
    
    log 1 "Slicing $CHROM_NAME in ${FILE}..."
    samtools view -@ $THREAD $FILE "${CHROM}" -b > "${OUT_DIR}/${FILE_NAME}.${CHROM_NAME}.bam"
    log 1 "Done slicing $CHROM_NAME"
    
    log 1 "Creating index file for ${FILE_NAME}.${CHROM_NAME}.bam"
    samtools index "${OUT_DIR}/${FILE_ID}.${CHROM_NAME}.bam"
    mv ${OUT_DIR}/${FILE_NAME}.${CHROM_NAME}.bam.bai ${OUT_DIR}/${FILE_NAME}.${CHROM_NAME}.bai 
    log 1 "Done indexing"
    log 1 ""
  done

  conda deactivate
}

make_config() {
  local PREFIX=$1
  local OUT_DIR=$2
  
  local SAMPLE_ID=$3
  local TUMOR_FILEID=$4
  local NORMAL_FILEID=$5

  local SLICE_CHROM_DB=$6
  local -A CHROM_NAME_ORD_ARR  # FIXME: no need for array parsing, but partition name,

  log 1 "Reading BAM slicing partition information in ${SLICE_CHROM_DB}..."
  while IFS="=" read -r key value; do
    CHROM_NAME_ORD_ARR["$key"]="$value"
    log 1 "partition ${key}: ${value}"
  done < $SLICE_CHROM_DB
  
  for CHROM_NAME in "${!CHROM_NAME_ORD_ARR[@]}"; do
    TUMOR_PART_BAM=$PREFIX/$TUMOR_FILEID.$CHROM_NAME.bam
    NORMAL_PART_BAM=$PREFIX/$NORMAL_FILEID.$CHROM_NAME.bam
    CONFIG_FILE=$OUT_DIR/${TUMOR_FILEID}_${NORMAL_FILEID}.${CHROM_NAME}.bam_config.txt

    log 1 "Creating ${CONFIG_FILE}..."
    touch $CONFIG_FILE
    echo -e "${NORMAL_PART_BAM}\t${PINDEL_LENGTH}\t${SAMPLE_ID}_N" > $CONFIG_FILE
    echo -e "${TUMOR_PART_BAM}\t${PINDEL_LENGTH}\t${SAMPLE_ID}_T" >> $CONFIG_FILE
    log 1 "Successly created ${CONFIG_FILE}"
    log 1
    done

    log 1 "Finished make configuration file for T:${TUMOR_FILEID}-N:${NORMAL_FILEID} pairs!"
    log 1 ""
}