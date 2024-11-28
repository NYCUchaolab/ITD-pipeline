#!/bin/sh

parse_sample_sheet() {
    local sample_sheet="$1"

    log 1 "Parsing sample sheet: $sample_sheet"
    
    Case_ID=""
    Tumor_fileID=""
    Normal_fileID=""

    shopt -s nocasematch

    while IFS=$'\t' read -r fileID fileName dataCategory dataType projectID caseID sampleID sampleType; do

        log 1 "Processing sample type: $sampleType..."

        Case_ID="$caseID"
        if [[ $sampleType =~ "tumor" ]]; then
            log 1 "Detected Tumor sample: $sampleID"
            Tumor_fileID="$fileID"
        elif [[ $sampleType =~ "Blood Derived Cancer" ]]; then
            log 1 "Detected Tumor sample: $sampleID"
            Tumor_fileID="$fileID"
        elif [[ $sampleType =~ "normal" ]]; then
            log 1 "Detected Normal sample: $sampleID"
            Normal_fileID="$fileID"
        else
            log 0 "What the fuck"
            exit 1
        fi
    done < <(tail -n +2 "$sample_sheet")  # Skip the header line
    shopt -u nocasematch

    # Log the Case ID
    log 1 "Case ID: ${Case_ID}"
    log 1 ""

    # Return the variables
    # echo "$Case_ID $Tumor_fileID $Tumor_sampleID $Normal_fileID $Normal_sampleID"
}