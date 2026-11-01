#!/usr/bin/env bash

set -euo pipefail

## 4. Assembly and binning
## 4.1 Metagenome assembly
time megahit \
    -1 all_reads_1.fastq \
    -2 all_reads_2.fastq \
    -t 64 \
    --presets meta-sensitive \
    -o CONTIG_OUTPUT_DIR

## 4.2 Metagenome binning with MetaBAT2
mkdir -p BWA_OUTPUT_DIR METABAT_OUTPUT_DIR

time bwa index CONTIG_OUTPUT_DIR/final.contigs.fa

time bwa mem \
    -t 64 \
    CONTIG_OUTPUT_DIR/final.contigs.fa \
    all_reads_1.fastq all_reads_2.fastq \
  | samtools sort -@ 64 \
    -o BWA_OUTPUT_DIR/OUTPUT.sorted.bam

time jgi_summarize_bam_contig_depths \
    --outputDepth SAMPLE.depth \
    BWA_OUTPUT_DIR/OUTPUT.sorted.bam

time metabat2 \
    -i CONTIG_OUTPUT_DIR/final.contigs.fa \
    -a SAMPLE.depth \
    -o METABAT_OUTPUT_DIR/bin
