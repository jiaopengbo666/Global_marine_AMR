#!/usr/bin/env bash
set -euo pipefail

##2. Quantification of ARGs and MGEs from clean reads
##2.1 Metagenomic quantification of ARGs
time args_oap stage_one \
  -i /CLEAN_READS/ \
  -o arg_stage_one/ \
  -t 20 \
  -f fastq
time args_oap stage_two \
  -i arg_stage_one/ \
  -o arg_stage_two/ \
  -t 20

##2.2 Metagenomic quantification of MGEs
time args_oap make_db \
  -i mobileOG-db_beatrix-1.6.All.faa
##Skip recalculation of read counts, 16S rRNA gene copies and cell counts.
time args_oap stage_one \
  --skip \      
  -i /CLEAN_READS/ \
  -o mge_stage_one/ \
  -f fastq \
  -t 12 \
  --database mobileOG-db_beatrix-1.6.All.faa

# Reuse metadata generated during ARG quantification
cp arg_stage_one/metadata.txt mge_stage_one/metadata.txt
time args_oap stage_two \
  -i mge_stage_one/ \
  -o mge_stage_two/ \
  -t 12 \
  --database mobileOG-db_beatrix-1.6.All.faa \
  --structure1 single-structure_MGE.txt
