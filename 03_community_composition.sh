#!/usr/bin/env bash

set -euo pipefail

# Example sample name used in Bracken output filenames.
i="SampleA"
## 3. Taxonomic profiling and abundance estimation from clean reads
## 3.1 MAG-based abundance estimation
time coverm genome \
  -1 /R1_fastq \
  -2 /R2_fastq \
  -p bwa-mem \
  -t 64 \
  -m mean trimmed_mean relative_abundance rpkm tpm \
  --genome-fasta-directory /drep_mags_dir -x fa \
  -o /mags_abundance.tsv
## 3.2 Read-based taxonomic profiling and abundance estimation
time kraken2 \
  --threads 10 \
  --db /Karken2_db/ \
  /all_reads/all_reads_1.fastq /all_reads/all_reads_2.fastq \
  --paired \
  --report /kraken_run/karken_report.txt \
  --use-names > /kraken_run/kraken2_anno.output \
  2>/kraken_run/kraken2_anno.error
time bracken \
  -d /Karken2_db/ \
  -i /kraken_run/karken_report.txt \
  -o /kra_run/Species/${i} \
  -l S 
time bracken \
  -d /Karken2_db/ \
  -i /kraken_run/karken_report.txt \
  -o /kra_run/Genus/${i} \
  -l G 
time bracken \
  -d /Karken2_db/ \
  -i /kraken_run/karken_report.txt \
  -o /kra_run/Family/${i} \
  -l F 
time bracken \
  -d /Karken2_db/ \
  -i /kraken_run/karken_report.txt \
  -o /kra_run/Order/${i} \
  -l O 
time bracken \
  -d /Karken2_db/ \
  -i /kraken_run/karken_report.txt \
  -o /kra_run/Phylum/${i} \
  -l P
