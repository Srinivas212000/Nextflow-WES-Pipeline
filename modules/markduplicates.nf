process MARK_DUPLICATES {

    tag "${sample_id}"

    publishDir "${projectDir}/results/markduplicates", mode: 'copy'

    input:
    tuple val(sample_id), path(sam)

    output:
    tuple val(sample_id), path("${sample_id}_dedup.bam"), emit: dedup_bam

    script:
    """
    gatk MarkDuplicatesSpark \
        -I ${sam} \
        -O ${sample_id}_dedup.bam
    """
}
