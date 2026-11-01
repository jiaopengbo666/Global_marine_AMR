#!/usr/bin/env bash

set -euo pipefail

##10. Plasmid prediction
##10.1 Plasmid prediction with geNomad
time genomad end-to-end \
  --cleanup \
  --threads 10 \
  --splits 10 \
  /input_file /genomad_output /genomad_db/

##10.2 Plasmid prediction with PlasX
time anvi-script-reformat-fasta \
  --simplify-names /input_file \
  -o /clean_fna \
  --report-file /report_file.txt
time anvi-gen-contigs-database -L 0 -T 20 \
  --project-name arg \
  -f /clean_fna -o /clean.db
time anvi-export-gene-calls --gene-caller prodigal \
  -c /clean.db -o /clean-gene-calls.txt
time anvi-run-ncbi-cogs -T 20 --cog-version COG14 \
  --cog-data-dir /COG/COG_2014/ -c /clean.db
time anvi-run-pfams -T 20 --pfam-data-dir /Pfam/Pfam_v32/ \
  -c /clean.db
time anvi-export-functions --annotation-sources COG14_FUNCTION,Pfam \
  -c /clean.db -o /clean-cogs-and-pfams.txt
time plasx search_de_novo_families -g /clean-gene-calls.txt \
  -o /clean-de-novo-families.txt --threads 20 --splits 32 --overwrite
time plasx predict -a /clean-cogs-and-pfams.txt /clean-de-novo-families.txt \
  -g /clean-gene-calls.txt -o /clean-scores.txt --overwrite
