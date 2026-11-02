#!/bin/bash
# All-versus-all ANI calculation.
# Reference script: Luke Diorio-Toth.

#SBATCH --job-name=fastani
#SBATCH --mem=80G
#SBATCH --cpus-per-task=12
#SBATCH --output=slurm_out/fastani_MQHQ/x_fastani_%A.out
#SBATCH --error=slurm_out/fastani_MQHQ/y_fastani_%A.err

eval $( spack load --sh fastani )

basedir="$PWD"
indir="${basedir}/d07_bin/dastool/HQandMQ_MAGs/allHQandMQ"
outdir="${basedir}/d28_fastani_HQMQ"

mkdir -p ${outdir}

find ${indir} -type f -name "*.fa" >> ${outdir}/MAG_paths.txt

set -x
time fastANI --ql ${outdir}/MAG_paths.txt \
            --rl ${outdir}/MAG_paths.txt \
            -o ${outdir}/fastani_out.txt \
            -t ${SLURM_CPUS_PER_TASK}
fastANI --ql ./HGT/QL_list.txt   --rl ./HGT/RL_list.txt   -o ./HGT/fastani_out.txt  -t 32
RC=$?
set +x

if [ $RC -eq 0 ]
then
  echo "Job completed successfully!"
else
  echo "Error occurred!"
  exit $RC
fi
