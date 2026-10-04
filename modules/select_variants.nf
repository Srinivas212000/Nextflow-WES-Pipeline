process SELECT_VARIANTS {

    tag "${sample_id}"

    publishDir "${projectDir}/results/select_variants", mode: 'copy'

    input:
    tuple val(sample_id), path(raw_vcf)
    path reference
    path reference_index
    path reference_dict

    output:
    tuple val(sample_id), path("${sample_id}.raw_snps.vcf"), emit: raw_snps
    tuple val(sample_id), path("${sample_id}.raw_indels.vcf"), emit: raw_indels

    script:
    """
    gatk SelectVariants \
        -R ${reference} \
        -V ${raw_vcf} \
        --select-type-to-include SNP \
        -O ${sample_id}.raw_snps.vcf

    gatk SelectVariants \
        -R ${reference} \
        -V ${raw_vcf} \
        --select-type-to-include INDEL \
        -O ${sample_id}.raw_indels.vcf
    """
}
