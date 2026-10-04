# Nextflow WES Variant Calling Pipeline

A reproducible **Whole Exome Sequencing (WES) variant-calling pipeline** developed using **Nextflow DSL2**. The workflow processes paired-end FASTQ files through quality control, read alignment, duplicate marking, alignment and insert-size metrics, germline variant calling, variant selection, and variant filtration.

The pipeline was developed and tested in a **Linux/WSL environment using Miniconda**.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Workflow](#workflow)
- [Data Sources](#data-sources)
- [Test Dataset Preparation](#test-dataset-preparation)
- [Reference Genome Preparation](#reference-genome-preparation)
- [Environment and Software Versions](#environment-and-software-versions)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Installation](#installation)
- [Input Data and Configuration](#input-data-and-configuration)
- [Running the Pipeline](#running-the-pipeline)
- [Pipeline Steps](#pipeline-steps)
- [Results and Outputs](#results-and-outputs)
- [Intermediate File Management](#intermediate-file-management)
- [Important Notes](#important-notes)
- [Reproducibility](#reproducibility)


---

## Project Overview

This project implements a modular **WES analysis workflow using Nextflow DSL2**.

The pipeline starts with paired-end FASTQ files and performs the following major analysis steps:

- Raw-read quality control using FastQC
- QC report aggregation using MultiQC
- Read alignment using BWA-MEM
- BAM processing
- Sort and index
- Duplicate marking
- Alignment metrics generation
- Insert-size metrics generation
- Germline variant calling using GATK HaplotypeCaller
- Variant selection
- Variant filtration
- PASS variant selection
- Final filtered VCF generation

The workflow is organized into independent Nextflow modules, allowing individual analysis processes to be maintained and executed separately.

---

## Workflow

The overall workflow is:

```text
                  Paired-end FASTQ
                         │
                         ▼
                      FastQC
                         │
                         ▼
                      MultiQC
                         │
                         ▼
                     BWA-MEM
                         │
                         ▼
                  BAM Processing (Sort and index )
                         │
                         ▼
                 Mark Duplicates
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
      Alignment Metrics       Insert Size Metrics
              │                     │
              └──────────┬──────────┘
                         ▼
                GATK HaplotypeCaller
                         │
                         ▼
                  Variant Selection
                         │
                         ▼
                 Variant Filtration
                         │
                         ▼
                   PASS Selection
                         │
                         ▼
                  Final Filtered VCF
```

---

## Data Sources

### 1. Raw FASTQ Data

The raw WES sequencing data was obtained from the data availability section of the publication associated with **PMID: 38236904**.

**Dataset:**

> HG001: Exome sequencing of *Homo sapiens*: HG001 with Illumina NovaSeq 6000 IDT capture

**SRA accession:** `SRR14724473`

The raw sequencing files were downloaded using `wget` in a Linux/WSL environment.

Publication:

[PubMed — PMID: 38236904](https://pubmed.ncbi.nlm.nih.gov/38236904/?utm_source=chatgpt.com)

---

### 2. WES Target BED File

The target BED file was obtained from the data availability resources associated with the same publication.

The BED file corresponds to the **IDT capture design** and was used for the WES target-region analysis.

The target BED file should be compatible with the reference genome assembly used for the analysis.

---

### 3. Reference Genome

The **GRCh38/hg38 reference genome** was downloaded from the UCSC Genome Browser using `wget`.

[UCSC hg38 Reference Genome](https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz?utm_source=chatgpt.com)

The reference genome was subsequently prepared with the required BWA, SAMtools, and GATK index/dictionary files.

---

## Test Dataset Preparation

The complete FASTQ dataset was not used for the workflow test because of the available RAM and computational resources in the local WSL environment.

To reduce computational requirements, **10,000 reads were sampled from each paired-end FASTQ file** using `seqtk`.

Example:

```bash
seqtk sample -s100 sample_R1.fastq.gz 10000 | gzip > test_R1.fastq.gz
seqtk sample -s100 sample_R2.fastq.gz 10000 | gzip > test_R2.fastq.gz
```

The resulting test FASTQ files were stored in the `data/` directory.

### Purpose of the Reduced Dataset

The reduced dataset was used for:

- Pipeline development
- Workflow testing
- Process validation
- Nextflow module integration
- End-to-end workflow execution

### Important Limitation

Because the test dataset contains only **10,000 reads per paired-end FASTQ file**, the sequencing depth and coverage are substantially lower than those expected from the complete WES dataset.

Therefore, the resulting:

- Coverage
- Depth
- Alignment statistics
- Variant counts

should be interpreted as **pipeline validation results** and not as representative results from the complete HG001 WES dataset.

---

## Reference Genome Preparation

The GRCh38/hg38 reference genome was prepared separately before running the workflow.

The following files are required in the `reference/` directory:

```text
reference/
├── hg38.fa
├── hg38.fa.fai
├── hg38.dict
├── hg38.fa.amb
├── hg38.fa.ann
├── hg38.fa.bwt
├── hg38.fa.pac
└── hg38.fa.sa
```

### BWA Index

The reference genome was indexed using:

```bash
bwa index hg38.fa
```

This generates:

```text
hg38.fa.amb
hg38.fa.ann
hg38.fa.bwt
hg38.fa.pac
hg38.fa.sa
```

### SAMtools FASTA Index

The FASTA index was generated using:

```bash
samtools faidx hg38.fa
```

This generates:

```text
hg38.fa.fai
```

### GATK Sequence Dictionary

The GATK sequence dictionary was generated using:

```bash
gatk CreateSequenceDictionary -R hg38.fa
```

This generates:

```text
hg38.dict
```

### Why Reference Preparation Is Not Included in the Workflow

Reference indexing is a one-time preparation step and can require significant computational resources.

To avoid repeating this preparation every time the pipeline is executed, the reference genome and all required index/dictionary files were prepared separately.

The current Nextflow workflow therefore expects an **already prepared reference genome** and begins with the alignment stage.

---

## Environment and Software Versions

The pipeline was developed and tested in a **Miniconda-managed Linux/WSL environment**.

### Conda Environment

Create the dedicated environment:

```bash
conda create -n nextflow-wes
```

Activate it:

```bash
conda activate nextflow-wes
```

Install the required software and dependencies listed below.

### Software Versions

| Software | Version | Purpose |
|---|---:|---|
| Nextflow | 26.04.6 | Workflow orchestration |
| FastQC | 0.12.1 | Raw-read quality control |
| MultiQC | 1.35 | QC report aggregation |
| BWA-MEM | 0.7.19 | Read alignment |
| SAMtools | 1.21 | BAM/FASTA processing |
| GATK | 4.6.2.0 | Variant calling and processing |
| HTSJDK | 4.2.0 | GATK dependency |
| Picard | 3.4.0 | BAM metrics and duplicate processing |

### Nextflow

```text
N E X T F L O W
version 26.04.6 build 12646
created 09-07-2026 18:49 UTC
```

The workflow is implemented using **Nextflow DSL2**.

---

## Project Structure

### Local Project Structure

The complete local environment used to execute the pipeline contains:

```text
Nextflow-WES-Pipeline/
│
├── bed/
│   └── <IDT capture BED file>
│
├── data/
│   ├── test_R1.fastq.gz
│   └── test_R2.fastq.gz
│
├── reference/
│   ├── hg38.fa
│   ├── hg38.fa.fai
│   ├── hg38.dict
│   ├── hg38.fa.amb
│   ├── hg38.fa.ann
│   ├── hg38.fa.bwt
│   ├── hg38.fa.pac
│   └── hg38.fa.sa
│
├── modules/
│   ├── alignment_metrics.nf
│   ├── bwa_mem.nf
│   ├── fastqc.nf
│   ├── haplotypecaller.nf
│   ├── insert_size_metrics.nf
│   ├── markduplicates.nf
│   ├── select_pass.nf
│   ├── select_variants.nf
│   └── variant_filtration.nf
│
├── results/
│   ├── alignment_metrics/
│   ├── bwa/
│   ├── fastqc/
│   ├── haplotypecaller/
│   ├── insert_size_metrics/
│   ├── markduplicates/
│   ├── multiqc/
│   ├── select_pass/
│   ├── select_variants/
│   └── variant_filtration/
│
├── main.nf
└── nextflow.config
```

### GitHub Repository

Large sequencing and reference files are not included in the repository.

The GitHub repository contains the pipeline implementation:

```text
Nextflow-WES-Pipeline/
│
├── main.nf
├── nextflow.config
│
└── modules/
    ├── alignment_metrics.nf
    ├── bwa_mem.nf
    ├── fastqc.nf
    ├── haplotypecaller.nf
    ├── insert_size_metrics.nf
    ├── markduplicates.nf
    ├── select_pass.nf
    ├── select_variants.nf
    └── variant_filtration.nf
```

Example final outputs are maintained separately in the `finalvcf_metrics/` directory for demonstration purposes.

---

## Requirements

Before running the pipeline, ensure that the following are available:

1. Miniconda/Conda
2. Nextflow
3. Required bioinformatics tools
4. Paired-end FASTQ files
5. Compatible WES target BED file
6. GRCh38/hg38 reference genome
7. Required BWA indexes
8. FASTA index (`.fai`)
9. GATK sequence dictionary (`.dict`)

The reference genome and target BED file must correspond to the same genome assembly.

---

## Installation

### Step 1: Create the Conda Environment

```bash
conda create -n nextflow-wes
```

Activate the environment:

```bash
conda activate nextflow-wes
```

Install the required software packages and dependencies listed in the [Software Versions](#environment-and-software-versions) section.

---

### Step 2: Prepare the Required Files

The local project should contain:

```text
bed/
data/
reference/
modules/
main.nf
nextflow.config
```

The `data/` directory should contain the paired-end FASTQ files.

The `bed/` directory should contain the appropriate WES capture target BED file.

The `reference/` directory should contain the prepared hg38 reference genome and required indexes.

---

### Step 3: Verify the Reference Files

Before running the pipeline, verify that the following files are available:

```text
hg38.fa
hg38.fa.fai
hg38.dict
hg38.fa.amb
hg38.fa.ann
hg38.fa.bwt
hg38.fa.pac
hg38.fa.sa
```

---

## Input Data and Configuration

This implementation does not require a separate sample sheet.

The pipeline uses the input paths and parameters defined in:

```text
nextflow.config
```

The workflow expects paired-end FASTQ files and the required reference genome and BED file to be available in the appropriate directories.

The main workflow is defined in:

```text
main.nf
```

Individual pipeline processes are implemented as separate modules under:

```text
modules/
```

---

## Running the Pipeline

Activate the Conda environment:

```bash
conda activate nextflow-wes
```

Navigate to the project root:

```bash
cd Nextflow-WES-Pipeline
```

Run the workflow:

```bash
nextflow run main.nf
```

The pipeline executes the processes defined in `main.nf` using the configuration specified in `nextflow.config`.

---

## Pipeline Steps

### 1. FastQC

FastQC is used to evaluate the quality of the input FASTQ files.

Quality metrics include:

- Per-base sequence quality
- Sequence length
- GC content
- Adapter content
- Sequence duplication

---

### 2. MultiQC

MultiQC aggregates the FastQC results into a consolidated quality-control report.

---

### 3. Read Alignment

Paired-end reads are aligned against the GRCh38/hg38 reference genome using **BWA-MEM**.

The pre-generated BWA indexes are used during alignment.

---

### 4. BAM Processing

The aligned reads are processed and sorted to generate BAM files suitable for downstream analysis.

---

### 5. Duplicate Marking

Duplicate reads are identified and marked using the duplicate-marking process.

---

### 6. Alignment Metrics

Alignment metrics are generated to evaluate the mapping characteristics of the sequencing data.

---

### 7. Insert-Size Metrics

Insert-size metrics are generated to evaluate the fragment-size distribution of the sequencing library.

---

### 8. Germline Variant Calling

Germline SNVs and indels are called using:

```text
GATK HaplotypeCaller
```

---

### 9. Variant Selection

Variants are selected into the required categories for downstream filtration.

---

### 10. Variant Filtration

Quality-based filtering is applied to the called variants according to the configured filtering criteria.

---

### 11. PASS Variant Selection

Variants that pass the configured filtering criteria are selected for the final analysis-ready VCF.

---

## Results and Outputs

All pipeline-generated outputs are organized under the:

```text
results/
```

directory.

The current workflow generates separate output directories for the individual pipeline processes:

```text
results/
├── alignment_metrics/
├── bwa/
├── fastqc/
├── haplotypecaller/
├── insert_size_metrics/
├── markduplicates/
├── multiqc/
├── select_pass/
├── select_variants/
└── variant_filtration/
```

Each directory contains the outputs generated by its corresponding Nextflow process.

### Final Demonstration Outputs

To make the important results easily accessible in the GitHub repository, selected final outputs have been copied into:

```text
finalvcf_metrics/
```

This directory contains:

```text
finalvcf_metrics/
├── Analysis-ready VCF
├── Alignment metrics
└── Insert-size metrics
```

These files provide representative outputs from the test dataset and demonstrate the successful execution of the pipeline.

### Analysis-Ready VCF

The analysis-ready VCF contains the final variants that passed the configured variant filtration criteria.

### Alignment Metrics

The alignment metrics provide information about the performance and characteristics of the read alignment.

### Insert-Size Metrics

The insert-size metrics provide information about the fragment-size distribution of the sequencing library.

> **Important:** These example outputs were generated using the reduced 10,000-read test dataset. Therefore, coverage, depth, alignment statistics, and variant counts should be interpreted as pipeline-validation results rather than representative results from the complete WES dataset.

---

## Intermediate File Management

Nextflow DSL2 uses the `work/` directory to store intermediate files generated during the execution of individual processes.

The `work/` directory contains process-specific intermediate files and execution data used by Nextflow for workflow execution and caching.

The workflow separates process outputs into their corresponding directories under:

```text
results/
```

For example:

```text
results/fastqc/
results/bwa/
results/markduplicates/
results/haplotypecaller/
results/variant_filtration/
```

This organization makes it possible to inspect intermediate process outputs while keeping the final demonstration outputs separately organized.

After successful pipeline execution and verification of the required results, the `work/` directory can be removed if the intermediate files are no longer required.

The `work/` directory is not intended to be committed to GitHub.

---

## Important Notes

### 1. Reduced Test Dataset

The workflow was tested using only **10,000 reads per paired-end FASTQ file** because the complete WES dataset required more computational resources than were available in the local WSL environment.

### 2. Coverage and Depth

The reduced dataset results in lower sequencing depth and coverage.

Consequently, the final VCF may contain fewer variants than would be expected from analysis of the complete WES dataset.

### 3. Reference Genome

The pipeline uses:

```text
GRCh38 / hg38
```

The reference genome, BWA indexes, FASTA index, sequence dictionary, and target BED file must be compatible with the same reference assembly.

### 4. Reference Preparation

Reference indexing and dictionary generation were performed separately and are not included as processes in the current workflow.

This avoids repeating computationally expensive reference-preparation steps during every pipeline execution.

### 5. Large Files

The following files are intentionally not included in the GitHub repository:

- Raw FASTQ files
- Full reference genome
- Reference genome indexes
- Nextflow `work/` directory
- Other large intermediate files

The required files must be prepared locally before running the workflow.

---

## Reproducibility

This project uses **Nextflow DSL2** and a modular workflow design.

The workflow separates individual analysis processes into reusable Nextflow modules:

```text
modules/
├── alignment_metrics.nf
├── bwa_mem.nf
├── fastqc.nf
├── haplotypecaller.nf
├── insert_size_metrics.nf
├── markduplicates.nf
├── select_pass.nf
├── select_variants.nf
└── variant_filtration.nf
```

The software versions used for development and testing are documented in this README.

The combination of:

- Nextflow workflow definitions
- Modular process files
- `nextflow.config`
- Documented software versions
- Defined reference genome
- Defined target BED file
- Test dataset preparation procedure

provides a reproducible framework for running the WES workflow.

---

## Limitations

This project was developed and tested in a resource-limited local WSL environment.

The 10,000-read dataset was used specifically to validate the workflow while reducing computational requirements.

Therefore, the current test results should not be considered representative of a complete WES analysis.

For full-scale WES analysis, the complete sequencing dataset should be processed using an environment with adequate CPU, RAM, storage, and computational resources.

The workflow should also be independently validated before use in research or clinical production environments.

---


## Disclaimer

This pipeline is intended for **bioinformatics workflow development, testing, and demonstration purposes**.

The reduced test dataset and example outputs are provided to demonstrate workflow execution and should not be used as a substitute for a complete WES analysis.
