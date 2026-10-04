process INSERT_SIZE_METRICS {

    tag "${sample_id}"

    publishDir "${projectDir}/results/insert_size_metrics", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}_insert_size_metrics.txt"), emit: insert_size_metrics
    path "${sample_id}_insert_size_histogram.pdf", emit: histogram

    script:
    """
    gatk CollectInsertSizeMetrics \
        INPUT=${bam} \
        OUTPUT=${sample_id}_insert_size_metrics.txt \
        HISTOGRAM_FILE=${sample_id}_insert_size_histogram.pdf
    """
}
