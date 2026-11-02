#!/bin/bash
# Build nucleotide BLAST databases.
# Reference script: Bejan Mahmud.
# sample_list.txt contains MAG filenames.

basedir="./HGT/"
indir="${basedir}/MAG"
outdir="${basedir}/d22_BLASTn_HQMQ/db"

max=$(wc -l sample_list.txt  | awk '{print $1}')

for  ((SLURM_ARRAY_TASK_ID=1; SLURM_ARRAY_TASK_ID<=100; SLURM_ARRAY_TASK_ID+=1));
do

sample=`sed -n ${SLURM_ARRAY_TASK_ID}p ${basedir}/sample_list.txt`

mkdir -p ${outdir}/${sample}

set -x

time makeblastdb -in ${indir}/${sample} \
        -parse_seqids \
        -blastdb_version 5 \
        -title "${sample}_BLASTdb" \
        -dbtype nucl \
        -out ${outdir}/${sample}/${sample}

RC=$?

set +x
if [ $RC -eq 0 ]
then
  echo "Job completed successfully"
else
  echo "Error Occurred!"
  exit $RC
fi

done
