#!/bin/bash
# All-versus-all BLASTn alignment.
# Reference script: Bejan Mahmud.

basedir="./HGT/"
indir="${basedir}/MAG"
outdir="${basedir}/test_output/BLASTn"

max=$(wc -l ./HGT/sample_list.txt  | awk '{print $1}')

for  ((SLURM_ARRAY_TASK_ID=1; SLURM_ARRAY_TASK_ID<=${max}; SLURM_ARRAY_TASK_ID+=1));
do

sample=`sed -n ${SLURM_ARRAY_TASK_ID}p ${basedir}/sample_list.txt`

mkdir -p ${outdir}

set -x

for ((i=1; i<=${max}; i+=1));
do
  [ ${i} -eq ${SLURM_ARRAY_TASK_ID} ] && continue
  subject=`sed -n ${i}p ${basedir}/sample_list.txt`
  echo "Blasting ${sample} with ${subject}"
  time blastn \
          -query ${indir}/${sample} \
          -db ${basedir}/d22_BLASTn_HQMQ/db/${subject}/${subject} \
          -outfmt 6 \
          -perc_identity 99 \
          -out ${outdir}/${sample}_${subject}.txt \
          -num_threads 13
done

cat ${outdir}/${sample}_*.txt > ${outdir}/merged_${sample}.txt
rm ${outdir}/${sample}_*.txt

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
