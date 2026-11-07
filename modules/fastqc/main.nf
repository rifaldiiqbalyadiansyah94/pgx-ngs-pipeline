process FASTQC {
    tag "$sample_id"
    publishDir "${params.outdir}/qc/fastqc", mode: 'copy'

    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*.zip"),  emit: zip
    tuple val(sample_id), path("*.html"), emit: html

    script:
    """
    fastqc --threads ${task.cpus} --outdir . ${reads}
    """
}
