#!/usr/bin/env bash

set -euo pipefail

##8. ORF prediction with Prodigal
time prodigal \
  -i /target.fa \
  -a genes.faa \
  -o /target.gbk \
  -d /target.fna \
  -p meta

##9. Contig-level annotation of ARGs, MGEs, virulence factor genes and taxonomy
##9.1 ARG annotation
time blastp -task blastp \
  -db /data1/SARG3.2.1-S/3.2.1-S/SARG3.2.1-S \
  -query genes.faa \
  -evalue 1e-5 \
  -num_threads 70 \
  -max_target_seqs 5 \
  -out ARG.txt \
  -outfmt "6 qseqid sseqid pident qcovhsp mismatch gapopen qstart qend sstart send evalue bitscore"

##9.2 MGE annotation
time diamond blastp --query genes.faa \
  --db /Database/mobile_OG_db/mobile.dmnd \
  --outfmt 6 qseqid sseqid pident qcovhsp mismatch gapopen qstart qend sstart send evalue bitscore \
  --out MGE.txt \
  --threads 32

##9.3 VFGs annotation
time diamond blastp --query genes.faa \
  --db /Database/VFDB.dmnd \
  --outfmt 6 qseqid sseqid pident qcovhsp mismatch gapopen qstart qend sstart send evalue bitscore \
  --out VFDB.txt \
  --threads 32

##9.4 Taxonomic annotation
time parallel -j 10 \
  "kraken2 --db /data1/Kraken2/ {} --threads 5 --use-names --output ./kraken2/{/.}.kraken2" \
  ::: ../6.contigs_sequence/Contigs/*.fna
time taxonkit lineage taxids.txt --data-dir ./ |
  taxonkit reformat --data-dir ./ \
    -f "{k}\t{p}\t{c}\t{o}\t{f}\t{g}\t{s}" -F \
  > taxid_with_names.txt
