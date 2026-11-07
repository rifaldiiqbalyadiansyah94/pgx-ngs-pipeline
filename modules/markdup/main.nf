process MARKDUP {
    tag "$sample_id"
    publishDir "${params.outdir}/alignment", mode: 'copy'

    container 'broadinstitute/gatk:4.6.0.0'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}.markdup.bam"), path("${sample_id}.markdup.bai"), emit: bam
    tuple val(sample_id), path("${sample_id}.markdup.metrics.txt"),                           emit: metrics

    script:
    """
    gatk --java-options "-Xmx${task.memory.toGiga() - 2}g" MarkDuplicates \\
        -I ${bam} \\
        -O ${sample_id}.markdup.bam \\
        -M ${sample_id}.markdup.metrics.txt \\
        --CREATE_INDEX true
    """
}
