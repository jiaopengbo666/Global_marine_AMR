#!/usr/bin/env bash

set -euo pipefail

##11. Phylogenetic tree construction
##11.1 Clustering of target gene sequences
time cd-hit \
    -i reference.faa \
    -o reference_clustered.faa \
    -c 0.95 \
    -n 5 \
    -d 0 \
    -T 40 \
    -M 16000

##11.2 Multiple sequence alignment with MAFFT
time mafft \
    --auto \
    --thread 40 \
    combined.faa > aligned.faa

##11.3 Alignment trimming with trimAl
time trimal \
    -in aligned.faa \
    -out trimmed.faa \
    -gappyout

##11.4 Phylogenetic tree inference with IQ-TREE
time iqtree \
    -s trimmed.faa \
    -st AA \
    -m MFP \
    -bb 1000 \
    -nt AUTO \
    -pre ARG_tree

