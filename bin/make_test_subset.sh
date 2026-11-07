#!/usr/bin/env bash
# Pemakaian: bin/make_test_subset.sh <url|bam|cram> <pharmcat_positions.vcf> <sample_id> [ref.fa]
set -euo pipefail

IN="$1"; POS="$2"; SAMPLE="$3"; REF="${4:-}"
OUT="data/test"
TMP="$OUT/tmp_${SAMPLE}"
mkdir -p "$OUT" "$TMP"

grep -v '^#' "$POS" | awk 'BEGIN{OFS="\t"}{s=$2-1000; if(s<0)s=0; print $1,s,$2+1000}' \
  | sort -k1,1 -k2,2n | bedtools merge -i - > "$OUT/pgx_regions.bed"

REFARG=()
[[ -n "$REF" ]] && REFARG=(-T "$REF")

for CHR in $(cut -f1 "$OUT/pgx_regions.bed" | uniq); do
  if [[ -s "$TMP/$CHR.bam" ]]; then
    echo "Lewati $CHR (sudah ada)"; continue
  fi
  awk -v c="$CHR" '$1==c' "$OUT/pgx_regions.bed" > "$TMP/$CHR.bed"
  OK=0
  for TRY in 1 2 3 4 5; do
    if timeout 600 samtools view -b -M "${REFARG[@]}" -L "$TMP/$CHR.bed" \
         -o "$TMP/$CHR.bam.part" "$IN"; then
      mv "$TMP/$CHR.bam.part" "$TMP/$CHR.bam"
      OK=1; break
    fi
    echo "Percobaan $TRY untuk $CHR gagal, mengulang..." >&2
    rm -f "$TMP/$CHR.bam.part"
    sleep 5
  done
  [[ $OK -eq 1 ]] || { echo "GAGAL total di $CHR" >&2; exit 1; }
  echo "Selesai $CHR"
done

samtools merge -f -o "$OUT/${SAMPLE}.subset.bam" "$TMP"/chr*.bam
samtools collate -u -O "$OUT/${SAMPLE}.subset.bam" \
  | samtools fastq -1 "$OUT/${SAMPLE}_R1.fastq.gz" \
                   -2 "$OUT/${SAMPLE}_R2.fastq.gz" \
                   -0 /dev/null -s /dev/null -n -

echo "Selesai: $OUT/${SAMPLE}_R1.fastq.gz dan _R2.fastq.gz"
