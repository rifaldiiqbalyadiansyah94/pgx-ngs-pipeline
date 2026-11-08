# pgx-ngs-pipeline

A Nextflow (DSL2) pharmacogenomics pipeline that goes from raw FASTQ to PharmCAT reports, built to process many samples in parallel.

```
FASTQ -> FastQC -> fastp -> BWA-MEM -> MarkDuplicates -> GATK HaplotypeCaller (GVCF)
      -> GenotypeGVCFs (PGx positions) -> PharmCAT -> HTML/JSON report  (+ MultiQC)
```

## Pipeline steps

| Step | Tool | Notes |
|---|---|---|
| Read QC | FastQC | raw read quality |
| Trimming | fastp | adapters and quality |
| Alignment | BWA (`bwa mem`) | GRCh38 with decoy/HLA contigs |
| Duplicates | GATK MarkDuplicates | |
| Variant calling | GATK 4.6.0.0 | GVCF, then GenotypeGVCFs restricted to PharmCAT positions (including reference calls) |
| PGx annotation | PharmCAT 3.4.0 | diplotypes, phenotypes, report |
| QC summary | MultiQC 1.25.1 | one report for all samples |

## Input

A samplesheet CSV with the columns `sample,sex,fastq_1,fastq_2`:

```csv
sample,sex,fastq_1,fastq_2
NA12878,female,data/test/NA12878_R1.fastq.gz,data/test/NA12878_R2.fastq.gz
NA19213,male,data/test/NA19213_R1.fastq.gz,data/test/NA19213_R2.fastq.gz
```

Required parameters:
- `--input`: samplesheet
- `--fasta`: GRCh38 reference (`GRCh38_full_analysis_set_plus_decoy_hla.fa`, uncompressed, `chr` contig naming)
- `--pgx_positions`: `pharmcat_positions.vcf` (must match the PharmCAT version used)

## Usage

Requirements: Nextflow and Docker.

```bash
nextflow run main.nf -profile docker,test \
  --fasta ref/GRCh38_full_analysis_set_plus_decoy_hla.fa \
  --pgx_positions ref/pharmcat_positions.vcf \
  -resume
```

To run your own data, replace `-profile docker,test` with `-profile docker` and pass `--input samplesheet.csv`.

A small test dataset can be built from public 1000 Genomes CRAM files with `bin/make_test_subset.sh`:

```bash
bin/make_test_subset.sh <cram_url> ref/pharmcat_positions.vcf <SAMPLE_ID> <ref.fa>
```

## Output

```
results/
  qc/            multiqc_report.html
  pharmcat/      <sample>.report.html, .report.json, .match.json, .phenotype.json
  pipeline_info/ timeline, report, trace
```

Example reports are in `docs/example_reports/`. Download the HTML files and open them in a browser.

## Validation

Test data are 30x NYGC 1000 Genomes samples, subset to reads around PGx genes (±1 kb) and compared with the GeT-RM (CDC) consensus genotypes:

| Sample | Sex | Population | Genes matching exactly |
|---|---|---|---|
| NA12878 | female | CEU | 10 |
| NA19213 | male | YRI | 8 |
| NA18564 | female | CHB | 10 |

The remaining differences come from:
- **Nomenclature**: UGT1A1 (*60 is not defined in PharmCAT), SLCO1B1 (*37 = c.388A>G, formerly *1B), CYP3A4 *1B, NAT2 (old nomenclature in GeT-RM).
- **CYP4F2**: the pipeline calls *3/*4 while GeT-RM reports *3/*3. The *4 variant is supported by the reads (24 of 43).
- **DPYD**: one extra *5 allele in one sample.
- **Correct calls of note**: NUDT15 *1/*3 (NA18564) and CYP2C9 *1/*6 (NA19213, an indel) were detected correctly.

## Limitations

- CYP2D6 cannot be called from a VCF by PharmCAT (it needs a dedicated structural variant caller).
- HLA genes are not covered.
- Indel/repeat positions can be flagged "missing variant input" because GATK reference records have a different form than PharmCAT expects. Variants that are actually present are still detected.
- Male chrX is called diploid (PharmCAT accepts homozygous calls; hemizygous ploidy is not implemented).
- Resources are tuned for a 15 GB RAM / 12 CPU machine, so adjust the per-process settings in `nextflow.config` for a server.

## Versions

Nextflow 26.10.4, GATK 4.6.0.0, PharmCAT 3.4.0, MultiQC 1.25.1.
