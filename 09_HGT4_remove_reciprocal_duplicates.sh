#!/bin/bash
# Remove reciprocal BLASTn hits from the joint alignment table.
# Reference script: Bejan Mahmud.

basedir="./HGT/"

indir="${basedir}/test_output/d22_BLASTn_HQMQ/"

set -x

python3 "$(dirname -- "${BASH_SOURCE[0]}")/09_HGT4_remove_reciprocal_duplicates.py" ./HGT/joint_BLASTn_allHQMQMAGs.txt ./HGT/joint_BLASTn_allHQMQMAGs_nodup_BK.txt

RC=$?

set +x

if [ $RC -eq 0 ]
then
  echo "Job completed successfully"
else
  echo "Error Occurred!"
  exit $RC
fi
