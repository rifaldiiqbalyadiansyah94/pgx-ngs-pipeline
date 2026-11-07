process PREPARE_REF {
    tag "$fasta.name"
    publishDir "${params.outdir}/reference", mode: 'copy', pattern: '*.{fai,dict}'

    container 'quay.io/biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:a34558545ae1413d94bde4578787ebef08027945-0'

    input:
    path fasta

    output:
    path fasta,                              emit: fasta
    path "${fasta}.fai",                     emit: fai
    path "${fasta.baseName}.dict",           emit: dict
    path "${fasta}.{amb,ann,bwt,pac,sa}",    emit: bwa_index

    script:
    """
    samtools faidx ${fasta}
    samtools dict ${fasta} -o ${fasta.baseName}.dict
    bwa index ${fasta}
    """
}
