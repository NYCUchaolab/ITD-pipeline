#!/bin/sh

# Source the parameters from the config file
source /home/data/data_Jeffery/ITD-detection/script/ITD_pipeline/parameters.config

# Open samtools env
conda activate WES_preprocessing_SNP

cd ${cwd}
############### slice bam ###############
for file_ID in download/*.bam
do
  # Extract the base name of the file without the extension
  file_id=$(basename ${file_ID} .bam)

  # Loop through all chromosomes specified in the chr array
  for chr in "${chr[@]}"; 
  do
    samtools view -@ 20 ${file_ID} ${chr} -b > slicebam/${file_id}.${chr}.bam
    samtools index slicebam/${file_id}.${chr}.bam
    mv slicebam/${file_id}.${chr}.bam.bai slicebam/${file_id}.${chr}.bai 
  done

  ############### Slice chr1 p and q arms ###############
  # 1. Define coordinates for chr1 p and q arms
  chr1_p_arm_coords="chr1:1-123400000"  # Example for chr1 p-arm
  chr1_q_arm_coords="chr1:123400001-248956422"  # Example for chr1 q-arm
  # 2. Slice chr1 p arm
  samtools view -@ 20 ${file_ID} ${chr1_p_arm_coords} -b > slicebam/${file_id}.chr1p.bam
  samtools index slicebam/${file_id}.chr1p.bam
  mv slicebam/${file_id}.chr1p.bam.bai slicebam/${file_id}.chr1p.bai 
  # 3. Slice chr1 q arm
  samtools view -@ 20 ${file_ID} ${chr1_q_arm_coords} -b > slicebam/${file_id}.chr1q.bam
  samtools index slicebam/${file_id}.chr1q.bam
  mv slicebam/${file_id}.chr1q.bam.bai slicebam/${file_id}.chr1q.bai
  
  ############### Slice chr2 p and q arms ###############
  # 1. Define coordinates for chr2 p and q arms
  chr2_p_arm_coords="chr2:1-92326171"  #chr2 p-arm
  chr2_q_arm_coords="chr2:92326172-242193529"  #chr2 q-arm
  # 2. Slice chr2 p arm
  samtools view -@ 20 ${file_ID} ${chr2_p_arm_coords} -b > slicebam/${file_id}.chr2p.bam
  samtools index slicebam/${file_id}.chr2p.bam
  mv slicebam/${file_id}.chr2p.bam.bai slicebam/${file_id}.chr2p.bai 
  # 3. Slice chr2 q arm
  samtools view -@ 20 ${file_ID} ${chr2_q_arm_coords} -b > slicebam/${file_id}.chr2q.bam
  samtools index slicebam/${file_id}.chr2q.bam
  mv slicebam/${file_id}.chr2q.bam.bai slicebam/${file_id}.chr2q.bai
  
  ############### Slice chr3 p and q arms ###############
  # 1. Define coordinates for chr3 p and q arms
  chr3_p_arm_coords="chr3:1-90998734"  #chr3 p-arm
  chr3_q_arm_coords="chr3:90998735-198295559"  #chr3 q-arm
  # 2. Slice chr3 p arm
  samtools view -@ 20 ${file_ID} ${chr3_p_arm_coords} -b > slicebam/${file_id}.chr3p.bam
  samtools index slicebam/${file_id}.chr3p.bam
  mv slicebam/${file_id}.chr3p.bam.bai slicebam/${file_id}.chr3p.bai 
  # 3. Slice chr3 q arm
  samtools view -@ 20 ${file_ID} ${chr3_q_arm_coords} -b > slicebam/${file_id}.chr3q.bam
  samtools index slicebam/${file_id}.chr3q.bam
  mv slicebam/${file_id}.chr3q.bam.bai slicebam/${file_id}.chr3q.bai
  
  ############### Slice chr7 p and q arms ###############
  # 1. Define coordinates for chr7 p and q arms
  chr7_p_arm_coords="chr7:1-60348388"  #chr7 p-arm
  chr7_q_arm_coords="chr7:60348389-159345973"  #chr7 q-arm
  # 2. Slice chr7 p arm
  samtools view -@ 20 ${file_ID} ${chr7_p_arm_coords} -b > slicebam/${file_id}.chr7p.bam
  samtools index slicebam/${file_id}.chr7p.bam
  mv slicebam/${file_id}.chr7p.bam.bai slicebam/${file_id}.chr7p.bai
  # 3. Slice chr7 q arm
  samtools view -@ 20 ${file_ID} ${chr7_q_arm_coords} -b > slicebam/${file_id}.chr7q.bam
  samtools index slicebam/${file_id}.chr7q.bam
  mv slicebam/${file_id}.chr7q.bam.bai slicebam/${file_id}.chr7q.bai
done
