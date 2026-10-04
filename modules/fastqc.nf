process FASTQC {

    tag "${sample_id}"

    publishDir "${projectDir}/results/fastqc", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "*.html", emit: qc_html
    path "*.zip", emit: qc_zip

    script:
    """
    fastqc ${reads}
    """
}


process MULTIQC {

    publishDir "${projectDir}/results/multiqc", mode: 'copy'

    input:
    path fastqc_results

    output:
    path "multiqc_report.html"
    path "multiqc_data"

    script:
    """
    multiqc . -o .
    """
}
