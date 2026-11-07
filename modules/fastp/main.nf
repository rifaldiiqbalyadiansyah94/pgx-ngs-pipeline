process FASTP {
    tag "$sample_id"
    publishDir "${params.outdir}/qc/fastp", mode: 'copy', pattern: '*.{json,html}'

    container 'quay.io/biocontainers/fastp:0.23.4--h5f740d0_0'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}_trimmed_R{1,2}.fastq.gz"), emit: reads
    tuple val(sample_id), path("${sample_id}.fastp.json"),              emit: json
    tuple val(sample_id), path("${sample_id}.fastp.html"),              emit: html

    script:
    """
    fastp \\
        --in1 ${reads[0]} --in2 ${reads[1]} \\
        --out1 ${sample_id}_trimmed_R1.fastq.gz \\
        --out2 ${sample_id}_trimmed_R2.fastq.gz \\
        --detect_adapter_for_pe \\
        --qualified_quality_phred 20 \\
        --length_required 50 \\
        --thread ${task.cpus} \\
        --json ${sample_id}.fastp.json \\
        --html ${sample_id}.fastp.html
    """
}
