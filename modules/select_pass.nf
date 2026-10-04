process SELECT_PASS {

    tag "${sample_id}"

    publishDir "${projectDir}/results/select_pass", mode: 'copy'

    input:
    tuple val(sample_id), path(filtered_snps), path(filtered_indels)

    output:
    tuple val(sample_id), path("${sample_id}.analysis-ready-snps.vcf"), emit: pass_snps
    tuple val(sample_id), path("${sample_id}.analysis-ready-indels.vcf"), emit: pass_indels
    tuple val(sample_id), path("${sample_id}.analysis-ready.vcf"), emit: final_vcf

    script:
    """
    gatk SelectVariants \
        --exclude-filtered \
        -V ${filtered_snps} \
        -O ${sample_id}.analysis-ready-snps.vcf

    gatk SelectVariants \
        --exclude-filtered \
        -V ${filtered_indels} \
        -O ${sample_id}.analysis-ready-indels.vcf

    gatk MergeVcfs \
        -I ${sample_id}.analysis-ready-snps.vcf \
        -I ${sample_id}.analysis-ready-indels.vcf \
        -O ${sample_id}.analysis-ready.vcf
    """
}
