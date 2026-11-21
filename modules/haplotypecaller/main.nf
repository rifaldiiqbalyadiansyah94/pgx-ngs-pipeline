process GATK_CALL {
    tag "$sample_id"
    publishDir "${params.outdir}/variants", mode: 'copy'

    container 'broadinstitute/gatk:4.6.0.0'

    input:
    tuple val(sample_id), path(bam), path(bai), val(sex)
    path fasta
    path fai
    path dict
    path pgx_positions
    path ploidy_bed

    output:
    tuple val(sample_id), path("${sample_id}.pgx.vcf.gz"), path("${sample_id}.pgx.vcf.gz.tbi"), emit: vcf

    script:
    // Males are hemizygous on non-PAR chrX: call those regions with ploidy 1.
    // Everyone else (female, unknown) keeps the default ploidy of 2.
    def ploidy_opt = (sex == 'male') ? "--ploidy-regions ${ploidy_bed}" : ''
    """
    gatk --java-options "-Xmx${task.memory.toGiga() - 2}g" HaplotypeCaller \\
        -R ${fasta} \\
        -I ${bam} \\
        -L ${pgx_positions} \\
        ${ploidy_opt} \\
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
