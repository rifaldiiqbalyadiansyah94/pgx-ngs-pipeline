process GATK_CALL {
    tag "$sample_id"
    publishDir "${params.outdir}/variants", mode: 'copy'

    container 'broadinstitute/gatk:4.6.0.0'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path fasta
    path fai
    path dict
    path pgx_positions

    output:
    tuple val(sample_id), path("${sample_id}.pgx.vcf.gz"), path("${sample_id}.pgx.vcf.gz.tbi"), emit: vcf

    script:
    """
    gatk --java-options "-Xmx${task.memory.toGiga() - 2}g" HaplotypeCaller \\
        -R ${fasta} \\
        -I ${bam} \\
        -L ${pgx_positions} \\
        -ERC GVCF \\
        -O ${sample_id}.g.vcf.gz

    gatk --java-options "-Xmx${task.memory.toGiga() - 2}g" GenotypeGVCFs \\
        -R ${fasta} \\
        -V ${sample_id}.g.vcf.gz \\
        -L ${pgx_positions} \\
        --include-non-variant-sites \\
        -O ${sample_id}.pgx.vcf.gz
    """
}
