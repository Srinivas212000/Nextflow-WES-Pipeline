nextflow.enable.dsl=2


// ========================================
// MODULES
// ========================================

include {
    FASTQC
} from './modules/fastqc'

include {
    MULTIQC
} from './modules/fastqc'

include {
    BWA_MEM
} from './modules/bwa_mem'

include {
    MARK_DUPLICATES
} from './modules/markduplicates'

include {
    ALIGNMENT_METRICS
} from './modules/alignment_metrics'

include {
    INSERT_SIZE_METRICS
} from './modules/insert_size_metrics'

include {
    HAPLOTYPECALLER
} from './modules/haplotypecaller'

include {
    SELECT_VARIANTS
} from './modules/select_variants'

include {
    VARIANT_FILTRATION
} from './modules/variant_filtration'

include {
    SELECT_PASS
} from './modules/select_pass'


// ========================================
// PARAMETERS
// ========================================

params.reads = "${projectDir}/data/*_{R1,R2}.fastq.gz"

params.reference = "${projectDir}/reference/hg38.fa"

params.reference_index = "${projectDir}/reference/hg38.fa.fai"

params.reference_dict = "${projectDir}/reference/hg38.dict"

params.bwa_indexes = "${projectDir}/reference/hg38.fa.{amb,ann,bwt,pac,sa}"

params.bed = "${projectDir}/bed/idt_capture_novogene.grch38.bed"


// ========================================
// WORKFLOW
// ========================================

workflow {

    // ====================================
    // INPUT FASTQ
    // ====================================

    reads_ch = channel.fromFilePairs(
        params.reads,
        checkIfExists: true
    )


    // ====================================
    // REFERENCE GENOME
    // ====================================

    reference_ch = channel.fromPath(
        params.reference,
        checkIfExists: true
    )


    // ====================================
    // REFERENCE FASTA INDEX
    // ====================================

    reference_index_ch = channel.fromPath(
        params.reference_index,
        checkIfExists: true
    )


    // ====================================
    // GATK SEQUENCE DICTIONARY
    // ====================================

    reference_dict_ch = channel.fromPath(
        params.reference_dict,
        checkIfExists: true
    )


    // ====================================
    // PRE-BUILT BWA INDEXES
    // ====================================

    bwa_indexes_ch = channel.fromPath(
        params.bwa_indexes,
        checkIfExists: true
    ).collect()


    // ====================================
    // WES TARGET BED
    // ====================================

    bed_ch = channel.fromPath(
        params.bed,
        checkIfExists: true
    )


    // ====================================
    // 1. FASTQC
    // ====================================

    FASTQC(reads_ch)


    // ====================================
    // 2. MULTIQC
    // ====================================

    fastqc_files = FASTQC.out.qc_html
        .mix(FASTQC.out.qc_zip)
        .collect()

    MULTIQC(fastqc_files)


    // ====================================
    // 3. BWA-MEM
    // ====================================

    bwa_ch = BWA_MEM(
        reads_ch,
        reference_ch,
        bwa_indexes_ch
    )


    // ====================================
    // 4. MARK DUPLICATES
    // ====================================

    dedup_ch = MARK_DUPLICATES(
        bwa_ch
    )


    // ====================================
    // 5. ALIGNMENT METRICS
    // ====================================

    ALIGNMENT_METRICS(
        dedup_ch,
        reference_ch
    )


    // ====================================
    // 6. INSERT SIZE METRICS
    // ====================================

    INSERT_SIZE_METRICS(
        dedup_ch
    )


    // ====================================
    // 7. HAPLOTYPECALLER
    // ====================================

    raw_vcf_ch = HAPLOTYPECALLER(
        dedup_ch,
        reference_ch,
        reference_index_ch,
        reference_dict_ch,
        bed_ch
    )


    // ====================================
    // 8. SELECT SNPs / INDELs
    // ====================================

    selected_variants = SELECT_VARIANTS(
        raw_vcf_ch,
        reference_ch,
        reference_index_ch,
        reference_dict_ch
    )


    // ====================================
    // 9. PREPARE SNP + INDEL FOR
    //    VARIANT FILTRATION
    // ====================================

    snps_ch = selected_variants.raw_snps

    indels_ch = selected_variants.raw_indels


    variants_for_filtering = snps_ch
        .map { sample_id, snps_vcf ->
            tuple(sample_id, snps_vcf)
        }
        .join(
            indels_ch.map { sample_id, indels_vcf ->
                tuple(sample_id, indels_vcf)
            }
        )
        .map { sample_id, snps_vcf, indels_vcf ->
            tuple(sample_id, snps_vcf, indels_vcf)
        }


    // ====================================
    // 10. VARIANT FILTRATION
    // ====================================

    filtered_variants = VARIANT_FILTRATION(
        variants_for_filtering,
        reference_ch,
        reference_index_ch,
        reference_dict_ch
    )


    // ====================================
    // 11. PREPARE FILTERED SNP + INDEL
    //     FOR SELECT PASS
    // ====================================

    filtered_snps_ch = filtered_variants.filtered_snps

    filtered_indels_ch = filtered_variants.filtered_indels


    variants_for_pass = filtered_snps_ch
        .map { sample_id, snps_vcf ->
            tuple(sample_id, snps_vcf)
        }
        .join(
            filtered_indels_ch.map { sample_id, indels_vcf ->
                tuple(sample_id, indels_vcf)
            }
        )
        .map { sample_id, snps_vcf, indels_vcf ->
            tuple(sample_id, snps_vcf, indels_vcf)
        }


    // ====================================
    // 12. SELECT PASS + MERGE VCFs
    // ====================================

    SELECT_PASS(
        variants_for_pass
    )
}
