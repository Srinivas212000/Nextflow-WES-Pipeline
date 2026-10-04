process ALIGNMENT_METRICS {

    tag "${sample_id}"

    publishDir "${projectDir}/results/alignment_metrics", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)
    path reference

    output:
    tuple val(sample_id), path("${sample_id}_alignment_metrics.txt"), emit: alignment_metrics

    script:
    """
    gatk CollectAlignmentSummaryMetrics \
        R=${reference} \
        I=${bam} \
        O=${sample_id}_alignment_metrics.txt
    """
}
