process BWA_MEM {

    tag "${sample_id}"

    publishDir "${projectDir}/results/bwa", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)
    path reference
    path bwa_indexes

    output:
    tuple val(sample_id), path("${sample_id}.sam"), emit: aligned_sam

    script:
    """
    bwa mem \
        -t 2 \
        -R '@RG\\tID:${sample_id}\\tPL:ILLUMINA\\tSM:${sample_id}' \
        ${reference} \
        ${reads[0]} \
        ${reads[1]} \
        > ${sample_id}.sam
    """
}
