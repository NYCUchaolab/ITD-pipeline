#!/bin/bash

# Input Parameters
cancer_type=$1
start_file=$2         # Start file number (e.g., 1)
end_file=$3            # End file number (e.g., 50)
input_dir=$4           # Directory containing the split sample sheets
output_file=$5         # Output merged file

# Validate input
if [[ -z "$cancer_type" || -z "$start_file" || -z "$end_file" || -z "$input_dir" || -z "$output_file" ]]; then
    echo "Usage: $0 <cancer_type> <start_file> <end_file> <input_dir> <output_file>"
    exit 1
fi

# Temporary file to collect rows
temp_file=$(mktemp)

# Merge specified range of files
for i in $(seq "$start_file" "$end_file"); do
    file="$input_dir/${cancer_type}_sample_$i.tsv"
    if [[ -f "$file" ]]; then
        tail -n +2 "$file" >> "$temp_file"  # Append data, skipping the header
    else
        echo "Warning: $file does not exist, skipping."
    fi
done

# Sort and remove duplicates
sorted_file=$(mktemp)
sort -u "$temp_file" > "$sorted_file"

# Add the header from the first file in the range
header_file="$input_dir/${cancer_type}_sample_$start_file.tsv"
if [[ -f "$header_file" ]]; then
    header=$(head -n 1 "$header_file")
    echo -e "$header" > "$output_file"
    cat "$sorted_file" >> "$output_file"
else
    echo "Error: Header file $header_file not found!"
    rm "$temp_file" "$sorted_file"
    exit 1
fi

# Cleanup
rm "$temp_file" "$sorted_file"

echo "Merged files sample_$start_file.tsv to sample_$end_file.tsv into $output_file (unique rows only)."
