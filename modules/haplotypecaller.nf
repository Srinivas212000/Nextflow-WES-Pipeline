process HAPLOTYPECALLER {

    tag "${sample_id}"

    publishDir "${projectDir}/results/haplotypecaller", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)
    path reference
    path reference_index
    path reference_dict
    path bed

    output:
    tuple val(sample_id), path("${sample_id}.raw.vcf"), emit: raw_vcf

    script:
    """
    gatk HaplotypeCaller \
        -R ${reference} \
        -I ${bam} \
        -L ${bed} \
        -O ${sample_id}.raw.vcf
    """
}
