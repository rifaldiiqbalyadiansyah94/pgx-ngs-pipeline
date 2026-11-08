#!/usr/bin/env nextflow

include { PREPARE_REF   } from './modules/ref_index/main.nf'
include { FASTQC        } from './modules/fastqc/main.nf'
include { FASTP         } from './modules/fastp/main.nf'
include { BWA_ALIGN } from './modules/bwa_mem2/main.nf'
include { MARKDUP       } from './modules/markdup/main.nf'
include { GATK_CALL     } from './modules/haplotypecaller/main.nf'
include { RUN_PHARMCAT  } from './modules/pharmcat/main.nf'
include { MULTIQC       } from './modules/multiqc/main.nf'

workflow {

    if (!params.input)         { error "Parameter --input (samplesheet CSV) is required" }
    if (!params.fasta)         { error "Parameter --fasta (GRCh38, uncompressed) is required" }
    if (!params.pgx_positions) { error "Parameter --pgx_positions (pharmcat_positions.vcf) is required" }

    ch_samples = channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)

    ch_reads = ch_samples.map { row ->
        tuple(
            row.sample as String,
            [ file(row.fastq_1, checkIfExists: true),
              file(row.fastq_2, checkIfExists: true) ]
        )
    }

    ch_samples
        .map { row -> "${row.sample}\t${row.sex ?: 'NA'}" }
        .collectFile(
            name: 'sample_metadata.tsv',
            newLine: true,
            storeDir: params.outdir,
            seed: "sample_id\tsex"
        )

    ch_fasta = channel.fromPath(params.fasta, checkIfExists: true)
    PREPARE_REF(ch_fasta)

    ch_pgx_pos = file(params.pgx_positions, checkIfExists: true)

    FASTQC(ch_reads)
    FASTP(ch_reads)

    BWA_ALIGN(
        FASTP.out.reads,
        PREPARE_REF.out.fasta.first(),
        PREPARE_REF.out.bwa_index.first()
    )
    MARKDUP(BWA_ALIGN.out.bam)

    GATK_CALL(
        MARKDUP.out.bam,
        PREPARE_REF.out.fasta.first(),
        PREPARE_REF.out.fai.first(),
        PREPARE_REF.out.dict.first(),
        ch_pgx_pos
    )

    RUN_PHARMCAT(
        GATK_CALL.out.vcf,
        PREPARE_REF.out.fasta.first(),
        PREPARE_REF.out.fai.first()
    )

    ch_qc = FASTQC.out.zip.map { id, f -> f }
        .mix(FASTP.out.json.map { id, f -> f })
        .mix(MARKDUP.out.metrics.map { id, f -> f })
        .collect()
    MULTIQC(ch_qc)
}
