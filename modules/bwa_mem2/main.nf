process BWA_ALIGN {
    tag "$sample_id"

    container 'quay.io/biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:a34558545ae1413d94bde4578787ebef08027945-0'

    input:
    tuple val(sample_id), path(reads)
    path fasta
    path index

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), emit: bam

    script:
    """
    bwa mem \\
        -t ${task.cpus} \\
        -R "@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA\\tLB:${sample_id}" \\
        ${fasta} ${reads[0]} ${reads[1]} \\
      | samtools sort -@ ${task.cpus} -o ${sample_id}.sorted.bam -
    """
}
