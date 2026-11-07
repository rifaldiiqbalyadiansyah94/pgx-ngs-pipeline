process MULTIQC {
    publishDir "${params.outdir}/qc", mode: 'copy'

    container 'quay.io/biocontainers/multiqc:1.25.1--pyhdfd78af_0'

    input:
    path qc_files

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_report_data",        emit: data

    script:
    """
    multiqc . --force --filename multiqc_report.html
    """
}
