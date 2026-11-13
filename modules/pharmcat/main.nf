process RUN_PHARMCAT {
    tag "$sample_id"
    publishDir "${params.outdir}/pharmcat", mode: 'copy'
    container "pgkb/pharmcat:${params.pharmcat_version}"

    input:
    tuple val(sample_id), path(vcf), path(tbi)

    output:
    tuple val(sample_id), path("${sample_id}.report.html"),    emit: html
    tuple val(sample_id), path("${sample_id}.report.json"),    emit: json
    tuple val(sample_id), path("${sample_id}.match.json"),     emit: match
    tuple val(sample_id), path("${sample_id}.phenotype.json"), emit: phenotype

    script:
    """
    pharmcat_pipeline ${vcf} \\
        -o . \\
        -bf ${sample_id} \\
        -reporterJson \\
        -reporterHtml
    """
}
