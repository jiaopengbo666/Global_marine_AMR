#!/usr/bin/env bash
# Reference scripts: Bejan Mahmud and Luke Diorio-Toth.

set -euo pipefail

usage() {
  cat <<'HELP'
Usage: bash 09_hgt_cli.sh -i MAG_DIR -o OUTPUT_DIR [-t THREADS] [-s STAGE]
  -i  MAG nucleotide FASTA directory (.fa, .fna, .fasta)
  -o  New output directory
  -t  BLASTn/FastANI threads (default: 13)
  -s  all, db, blast, filter, dedup, ani (default: all)
  -h  Show help
Requires: Bash, BLAST+, FastANI, Python 3 and GNU sort.
Outputs: joint_BLASTn_nodup.txt and fastani/fastani_out.txt.
Example: bash 09_hgt_cli.sh -i MAGs/ -o HGT/ -t 13
HELP
}
input=""; output=""; threads=13; stage=all
while getopts ':i:o:t:s:h' option; do
  case "$option" in
    i) input=$OPTARG ;; o) output=$OPTARG ;; t) threads=$OPTARG ;; s) stage=$OPTARG ;;
    h) usage; exit 0 ;; *) usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -eq 0 && -n "$input" && -n "$output" ]] || { usage >&2; exit 2; }
[[ "$threads" =~ ^[1-9][0-9]*$ ]] || { echo 'Threads must be a positive integer.' >&2; exit 2; }
case "$stage" in all|db|blast|filter|dedup|ani) ;; *) echo 'Unknown stage.' >&2; exit 2 ;; esac
command -v python3 >/dev/null || { echo 'Missing python3.' >&2; exit 1; }
case "$stage" in
  all) dependencies='makeblastdb blastn fastANI sort' ;;
  db) dependencies=makeblastdb ;; blast) dependencies=blastn ;;
  ani) dependencies=fastANI ;; dedup) dependencies=sort ;; *) dependencies='' ;;
esac
for tool in $dependencies; do command -v "$tool" >/dev/null || { echo "Missing dependency: $tool" >&2; exit 1; }; done
[[ -d "$input" ]] || { echo 'MAG directory does not exist.' >&2; exit 1; }
input=$(cd -- "$input" && pwd)
mkdir -p -- "$output"
output=$(cd -- "$output" && pwd)
[[ "$input" != "$output" ]] || { echo 'Input and output directories must differ.' >&2; exit 1; }

python3 - "$input" "$output/MAG_paths.txt" <<'PREPARE_PY'
from pathlib import Path
import sys
folder, manifest = Path(sys.argv[1]), Path(sys.argv[2])
files = sorted(p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in {'.fa', '.fna', '.fasta'})
if len(files) < 2:
    raise SystemExit('At least two MAG FASTA files are required.')
ids = set()
for p in files:
    if any(c.isspace() for c in str(p)):
        raise SystemExit('Use MAG paths without whitespace for BLAST/FastANI compatibility.')
    count = 0
    for line in p.open():
        if line.startswith('>'):
            fields = line[1:].split()
            if not fields:
                raise SystemExit(f'Empty FASTA identifier: {p.name}')
            identifier = fields[0]
            if identifier in ids:
                raise SystemExit(f'Duplicate contig ID: {identifier}. Contig IDs must be globally unique.')
            ids.add(identifier)
            count += 1
    if not count:
        raise SystemExit(f'No FASTA headers found: {p.name}')
content = chr(10).join(str(p.resolve()) for p in files) + chr(10)
if manifest.exists() and manifest.read_text() != content:
    raise SystemExit('Existing MAG manifest differs. Use a new output directory.')
manifest.write_text(content)
PREPARE_PY
mapfile -t mags < "$output/MAG_paths.txt"
mkdir -p "$output/db" "$output/blastn" "$output/filtered" "$output/fastani"
ensure_new() { [[ ! -e "$1" ]] || { echo "Output already exists: $1; use a new output directory." >&2; exit 1; }; }

## 9.1 BLAST database construction
if [[ "$stage" == all || "$stage" == db ]]; then
  for mag in "${mags[@]}"; do
    name=$(basename -- "$mag")
    ensure_new "$output/db/$name"
    mkdir -p "$output/db/$name"
    makeblastdb -in "$mag" -parse_seqids -blastdb_version 5 \
      -title "${name}_BLASTdb" -dbtype nucl -out "$output/db/$name/$name"
  done
fi

## 9.2 All-versus-all nucleotide sequence alignment
if [[ "$stage" == all || "$stage" == blast ]]; then
  for query in "${mags[@]}"; do
    qname=$(basename -- "$query")
    merged="$output/blastn/merged_${qname}.txt"
    ensure_new "$merged"
    : > "$merged"
    for subject in "${mags[@]}"; do
      [[ "$query" == "$subject" ]] && continue
      sname=$(basename -- "$subject")
      pair="$output/blastn/${qname}__${sname}.txt"
      ensure_new "$pair"
      blastn -query "$query" -db "$output/db/$sname/$sname" \
        -outfmt 6 -perc_identity 99 -out "$pair" -num_threads "$threads"
      cat "$pair" >> "$merged"
    done
  done
fi

## 9.3 Alignment length filtering (>=500 bp)
if [[ "$stage" == all || "$stage" == filter ]]; then
  for mag in "${mags[@]}"; do
    name=$(basename -- "$mag")
    filtered="$output/filtered/filtered_${name}.txt"
    ensure_new "$filtered"
    python3 - "$output/blastn/merged_${name}.txt" "$filtered" <<'FILTER_PY'
import sys
with open(sys.argv[1]) as source, open(sys.argv[2], 'w') as target:
    for line in source:
        if int(line.strip().split('\t')[3]) >= 500:
            target.write(line)
FILTER_PY
  done
fi

## 9.4 Removal of reciprocal duplicates
if [[ "$stage" == all || "$stage" == dedup ]]; then
  joint="$output/joint_BLASTn.txt"
  ensure_new "$joint"
  ensure_new "$output/joint_BLASTn_nodup.txt"
  : > "$joint"
  for mag in "${mags[@]}"; do
    name=$(basename -- "$mag")
    cat "$output/filtered/filtered_${name}.txt" >> "$joint"
  done
  (
    cd -- "$output"
    python3 - "$joint" "$output/joint_BLASTn_nodup.txt" <<'DEDUP_PY'

"""Remove reciprocal BLASTn contig pairs.
Usage: INPUT OUTPUT"""

import subprocess
import os
import sys

class DupFilter(object):
    def __init__(self, infile, outfile):
        self.infile = infile
        self.outfile = outfile
        self.set1 = '{}.set1'.format(outfile)
        self.set2 = '{}.set2'.format(outfile)
        self.set1sorted = '{}.sorted'.format(self.set1)
        self.set2sorted = '{}.sorted'.format(self.set2)

    def get_key(self, line, reverse=False):
        if line == b'':
            return None
        if not reverse:
            return line.split(b'\t',3)[0:2]
        else:
            return line.split(b'\t',3)[1::-1]

    def step1(self):
        with open(self.set1, "wb") as t1, open(self.set2, 'wb') as t2, open(self.outfile, 'wb') as f, open('single.debug', 'wb') as u:
            for line in open(self.infile, "rb"):
              pair = line.split(b'\t',3)[:2]
              if pair[0] > pair[1]:
                  t1.write(line)
              elif pair[0] < pair[1]:
                  t2.write(line)
              else:
                  u.write(line)
                  f.write(line)

    def step2(self):
        try:
            p1 = subprocess.Popen(['/usr/bin/sort', '-k', '1,1', '-k', '2,2', '-o', self.set1sorted, self.set1])
            p2 = subprocess.Popen(['/usr/bin/sort', '-k', '2,2', '-k', '1,1', '-o', self.set2sorted, self.set2])
            p1.wait()
            p2.wait()
            if p1.returncode or p2.returncode:
                raise RuntimeError("sort failed")
        except subprocess.CalledProcessError as e:
            raise(e)

    def step3(self):
        with open(self.set1sorted, "rb") as t1, open(self.set2sorted, 'rb') as t2, open(self.outfile, 'r+b') as f, open('unique.debug', 'wb') as u, open('paired.debug', 'wb') as p:
            f.seek(0,2)
            l1 = t1.readline()
            l2 = t2.readline()
            while True:
                k1,k2 = self.get_key(l1), self.get_key(l2, True)
                if k1 == k2 == None:
                    break
                elif k1 == k2:
                    f.write(l1)
                    p.write(l1)
                    l1 = t1.readline()
                    l2 = t2.readline()
                elif k2 is None or (k1 is not None and k1 < k2):
                    f.write(l1)
                    u.write(l1)
                    l1 = t1.readline()
                elif k1 is None or k2 < k1:
                    f.write(l2)
                    u.write(l2)
                    l2 = t2.readline()
    def step4(self):
        os.unlink(self.set1)
        os.unlink(self.set2)
        os.unlink(self.set1sorted)
        os.unlink(self.set2sorted)

if __name__ == '__main__':
    import time

    if len(sys.argv) != 3:
      print(__doc__)
      exit(1)

    infile = sys.argv[1]
    outfile = sys.argv[2]
    d = DupFilter(infile, outfile)
    t1 = time.time()
    d.step1()
    print("Step1: ", time.time() - t1)
    t2 = time.time()
    d.step2()
    print("Step2: ", time.time() - t2)
    t3 = time.time()
    d.step3()
    print("Step3: ", time.time() - t3)
    t4 = time.time()
    d.step4()
    print("Total: ", time.time() - t1)
DEDUP_PY
  )
fi

## 9.5 Pairwise ANI calculation with FastANI
if [[ "$stage" == all || "$stage" == ani ]]; then
  ensure_new "$output/fastani/fastani_out.txt"
  fastANI --ql "$output/MAG_paths.txt" --rl "$output/MAG_paths.txt" \
    -o "$output/fastani/fastani_out.txt" -t "$threads"
fi
printf 'Finished stage: %s\nOutput directory: %s\n' "$stage" "$output"
