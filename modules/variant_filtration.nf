process VARIANT_FILTRATION {

    tag "${sample_id}"

    publishDir "${projectDir}/results/variant_filtration", mode: 'copy'

    input:
    tuple val(sample_id), path(snps_vcf), path(indels_vcf)
    path reference
    path reference_index
    path reference_dict

    output:
    tuple val(sample_id), path("${sample_id}.filtered_snps.vcf"), emit: filtered_snps
    tuple val(sample_id), path("${sample_id}.filtered_indels.vcf"), emit: filtered_indels

    script:
    """
    gatk VariantFiltration \
        -R ${reference} \
        -V ${snps_vcf} \
        -O ${sample_id}.filtered_snps.vcf \
        -filter-name "QD_filter" \
        -filter "QD < 2.0" \
        -filter-name "FS_filter" \
        -filter "FS > 60.0" \
        -filter-name "MQ_filter" \
        -filter "MQ < 40.0" \
        -filter-name "SOR_filter" \
        -filter "SOR > 4.0" \
        -filter-name "MQRankSum_filter" \
        -filter "MQRankSum < -12.5" \
        -filter-name "ReadPosRankSum_filter" \
        -filter "ReadPosRankSum < -8.0"

    gatk VariantFiltration \
        -R ${reference} \
        -V ${indels_vcf} \
        -O ${sample_id}.filtered_indels.vcf \
        -filter-name "QD_filter" \
        -filter "QD < 2.0" \
        -filter-name "FS_filter" \
        -filter "FS > 200.0" \
        -filter-name "SOR_filter" \
        -filter "SOR > 10.0"
    """
}
