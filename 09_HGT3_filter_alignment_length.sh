#!/bin/bash
# Filter BLASTn alignments by length (>=500 bp).
# Reference script: Bejan Mahmud.

basedir="./HGT/"
indir="${basedir}/test_output/BLASTn"

max=$(wc -l ./HGT/sample_list.txt  | awk '{print $1}')

for  ((SLURM_ARRAY_TASK_ID=1; SLURM_ARRAY_TASK_ID<=${max}; SLURM_ARRAY_TASK_ID+=1));
do

sample=`sed -n ${SLURM_ARRAY_TASK_ID}p ./HGT/sample_list.txt`

set -x

python3 "$(dirname -- "${BASH_SOURCE[0]}")/09_HGT3_filter_alignment_length.py" ${indir}/merged_${sample}.txt ${indir}/filtered_${sample}.txt

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
