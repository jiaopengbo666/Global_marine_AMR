#!/usr/bin/env bash

set -euo pipefail

## 5. MAG quality assessment, dereplication and taxonomic classification
## 5.1 MAG quality assessment with CheckM
time checkm lineage_wf \
  /PATH/mags/ \
  /PATH/mags_checkm/ \
  -x fa \
  -t 8

## 5.2 Genome dereplication with dRep
# mags_paths.txt lists the paths to the input MAG FASTA files, one per line.
# dRep applies quality thresholds; the preceding CheckM results are not
# explicitly supplied to dRep in this example.
time dRep dereplicate \
  /PATH/mags_drep/ \
  -g mags_paths.txt \
  -comp 50 \
  -con 10 \
  -sa 0.95 \
  -p 60

## 5.3 Taxonomic classification with GTDB-Tk
# Classify the representative genomes retained by dRep.
time gtdbtk classify_wf \
  --cpus 20 \
  -x fa \
  --mash_db /mash_db \
  --genome_dir /PATH/mags_drep/dereplicated_genomes/ \
  --out_dir /GTDB_result
