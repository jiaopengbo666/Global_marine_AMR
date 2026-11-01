#!/usr/bin/env bash
set -euo pipefail

##1. Quality control
for f1 in *_1.fastq; do
    sample=$(basename "$f1" _1.fastq)
    time trimmomatic PE -threads 100 -phred33 \
        "${sample}_1.fastq" "${sample}_2.fastq" \
        "${sample}_clean_1.fastq" "${sample}_unpaired_1.fastq" \
        "${sample}_clean_2.fastq" "${sample}_unpaired_2.fastq" \
        ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done
