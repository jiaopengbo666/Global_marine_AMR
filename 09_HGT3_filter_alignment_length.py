#!/usr/bin/env python3
# Reference script: Bejan Mahmud.

"""Keep BLASTn alignments >=500 bp.
Usage: python3 09_HGT3_filter_alignment_length.py INPUT OUTPUT"""

import sys

if len(sys.argv) != 3:
  print(__doc__)
  exit()

input_file = sys.argv[1]
output_path = sys.argv[2]

output_file = open(output_path, "w")

for line in open(input_file, "r"):
    line = line.strip()
    length = line.split("\t")[3]
    if int(length) >= 500:
      print(line, file = output_file)

output_file.close()
