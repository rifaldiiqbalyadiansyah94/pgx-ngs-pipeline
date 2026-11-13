#!/usr/bin/env nextflow


include { PREP_REF } from './modules/prep_ref/main.nf'
include { FASTQC } from './modules/fastqc/main.nf'
include { FASTP } from './modules/fastp/main.nf'
include { BWA_MEM } from './modules/bwa_mem/main.nf'
include { MARKDUP } from './modules/markdup/main.nf'
include { GATK_CALL } from './modules/haplotypecaller/main.nf'
include { PHARM_CAT ) from './modules/pharmcat/main.nf'
include { MULTIQC } from './modules/multiqc/main.nf'

workflow {
	if (!params.input) {error "Parameter --input (samplesheet.csv) is required"}
	if (!params.fasta) {error "Parameter --fasta (GRCh38 ref_uncompressed) is required"}
	if (!parmas.pgx-positions) {error "parameter --pgx-positions (pharmcat_positions) is required"}

	ch_sample = channel
		.fromPath(params.input, checkIfExists: true)
		.splitCsv(header: true)

	ch_reads = ch_sample.map { row ->
		tuple(
			row.sample as String
			[file(row.fastq_1, checkIfExists: true),
			 file(row.fastq_2, checkIfExists: true)]
		)
	}

		
	ch_sample 
		.map {row -> "${row.sample}\t${row.sex ?: 'NA'}"}
		.collectFile(
			name: 'sample_metadata.tsv',
			newLine: true,
			storeDir: params.output,
			seed: "sample\tsex"
		)

	ch_fasta = channel.fromPath(params.fasta, checkIfExists: true)
	PREP_REF(ch_fasta)

	ch_pgx_pos = file(params.pgx_positions, checkIfExists: true)
	
	FASTQC(ch_reads)
	FASTP(ch_reads)

	BWA_ALIGN(
		FASTP.out.reads,
		PREP_REF.out.fasta.first(),
		PREP_REF.out.bwa_index.first()
	)

	MARKDUP(BWA_ALIGN.out.bam)

	GATK_CALL(
		MARKDUP.out.bam,
		PREP_REF.out.fasta.first(),
		PREP_REF.out.fai.first(),
		PREP_REF.out.dict.first(),
		ch_pgx_pos
	)

	PHARM_CAT(GATK_CALL.out.vcf)

	ch_qc = FASTQC.out.zip.map {id, f -> f}
		.mix(FASTP.out.json.map {id, f -> f})
		.mix(MARKDUP.out.metrics.map {id, f -> f})
		.collect()

	MULTIQC(ch_qc)
}












