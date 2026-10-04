# Nextflow WES Variant Calling Pipeline

A reproducible **Whole Exome Sequencing (WES) variant-calling pipeline** developed using **Nextflow DSL2**. The workflow processes paired-end FASTQ files through quality control, read alignment, duplicate marking, BAM sorting and indexing, alignment and insert-size metrics, germline variant calling, target-region restriction, variant filtration, and final PASS variant selection.

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
- [Target Region Restriction](#target-region-restriction)
- [Results and Outputs](#results-and-outputs)
- [Intermediate File Management](#intermediate-file-management)
- [Important Notes](#important-notes)
- [Reproducibility](#reproducibility)
- [Limitations](#limitations)

---

## Project Overview

This project implements a modular **WES analysis workflow using Nextflow DSL2**.

The pipeline starts with paired-end FASTQ files and performs the following major analysis steps:

- FASTQ-level quality control using FastQC
- Consolidated QC reporting using MultiQC
- Read alignment using BWA-MEM
- Duplicate marking
- BAM sorting
- BAM indexing
- Alignment metrics generation
- Insert-size metrics generation
- Germline variant calling using GATK HaplotypeCaller
- Exome target-region restriction using a BED file
- Variant selection
- Variant quality filtration
- PASS variant selection
- Final filtered VCF generation

The workflow is organized into independent Nextflow modules, allowing individual analysis processes to be maintained, tested, and reused.

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
                  BAM Processing
                         │
                         ▼
          Mark Duplicates + Sort + Index
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
      Alignment Metrics       Insert Size Metrics
              │                     │
              └──────────┬──────────┘
                         ▼
                GATK HaplotypeCaller
                  + Target BED
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

The BED file corresponds to the **IDT capture design** used for the WES analysis.

The target BED file is used during the **GATK HaplotypeCaller** variant-calling step to restrict variant calling to the intended exome capture regions.

The BED file must be compatible with the GRCh38/hg38 reference genome used by the pipeline.

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

A GATK-compatible sequence dictionary was generated using:

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

The current Nextflow workflow therefore expects an **already prepared reference genome** and proceeds directly to the alignment stage.

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
| FastQC | 0.12.1 | FASTQ quality control |
| MultiQC | 1.35 | QC report aggregation |
| BWA-MEM | 0.7.19 | Read alignment |
| SAMtools | 1.21 | BAM and FASTA processing |
| GATK | 4.6.2.0 | Variant calling and processing |
| HTSJDK | 4.2.0 | GATK dependency |
| Picard | 3.4.0 | Duplicate marking and alignment metrics |

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

The GitHub repository contains the pipeline implementation and selected demonstration outputs.

Large sequencing and reference files are not included.

```text
Nextflow-WES-Pipeline/
│
├── main.nf
├── nextflow.config
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
└── finalvcf_metrics/
    ├── analysis-ready VCF
    ├── alignment metrics
    └── insert-size metrics
```

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

The input paths and parameters are defined through:

```text
nextflow.config
```

The workflow requires:

- Paired-end FASTQ files
- Reference genome
- Reference genome indexes
- GATK sequence dictionary
- WES target BED file
- Output directory configuration

The main workflow is defined in:

```text
main.nf
```

Individual analysis processes are implemented as separate modules under:

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

### 1. FASTQ Quality Control — FastQC

FastQC is used to perform quality control on the input FASTQ files.

The QC analysis evaluates sequencing characteristics including:

- Per-base sequence quality
- Sequence length
- GC content
- Adapter content
- Sequence duplication

---

### 2. Consolidated QC Report — MultiQC

MultiQC aggregates the FastQC reports into a consolidated QC summary.

This provides an overall view of the quality of the sequencing input.

---

### 3. Read Alignment — BWA-MEM

Paired-end reads are aligned to the **GRCh38/hg38 reference genome** using BWA-MEM.

The pre-generated BWA index files are used during this step.

---

### 4. Duplicate Marking, BAM Sorting and Indexing

The duplicate-removal process performs the following operations:

1. Identifies and marks PCR/optical duplicate reads.
2. Sorts the resulting BAM file.
3. Generates the BAM index.

Therefore, BAM sorting and BAM indexing are performed as part of the **duplicate-marking/removal step**.

The resulting sorted and indexed BAM files are used for downstream metrics and variant calling.

---

### 5. Alignment Metrics

Alignment metrics are generated from the processed BAM files.

These metrics are used to evaluate the quality and characteristics of the read alignment.

---

### 6. Insert-Size Metrics

Insert-size metrics are generated to assess the fragment-size distribution of the sequencing library.

---

### 7. Germline Variant Calling — GATK HaplotypeCaller

Germline SNVs and indels are called using:

```text
GATK HaplotypeCaller
```

The exome target BED file is supplied during variant calling to restrict the analysis to the intended target regions.

---

### 8. Variant Selection

Variants are selected into the required categories for downstream processing.

This stage prepares the variant calls for quality filtration.

---

### 9. Variant Filtration

Quality-based variant filtering is applied according to the filtering criteria configured in the workflow.

The purpose of this step is to identify variants that satisfy the defined quality requirements.

---

### 10. PASS Variant Selection

Variants that pass the configured filtration criteria are selected to generate the final analysis-ready variant set.

---

## Target Region Restriction

The pipeline accepts an **exome target BED file** as an input.

The BED file is used during the **GATK HaplotypeCaller** step to restrict variant calling to the intended exome capture regions.

This ensures that the variant-calling analysis is targeted to the regions represented by the selected WES capture design.

The target BED file must be compatible with the **GRCh38/hg38** reference genome used for alignment and variant calling.

---

## Results and Outputs

All pipeline-generated outputs are organized under:

```text
results/
```

The workflow creates separate output directories for the individual analysis processes:

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

### Output Description

| Directory | Description |
|---|---|
| `fastqc/` | FASTQ-level quality-control reports |
| `multiqc/` | Consolidated QC report |
| `bwa/` | Alignment outputs |
| `markduplicates/` | Duplicate-marked, sorted and indexed BAM files |
| `alignment_metrics/` | Alignment quality metrics |
| `insert_size_metrics/` | Insert-size metrics |
| `haplotypecaller/` | GATK HaplotypeCaller outputs |
| `select_variants/` | Selected variant subsets |
| `variant_filtration/` | Filtered variant outputs |
| `select_pass/` | Final PASS variant outputs |

---

## Final Demonstration Outputs

To make the most important results easily accessible for review, selected final outputs were copied into:

```text
finalvcf_metrics/
```

This folder contains:

```text
finalvcf_metrics/
├── Analysis-ready VCF
├── Alignment metrics
└── Insert-size metrics
```

### Analysis-Ready VCF

The analysis-ready VCF contains the final filtered variant calls generated by the workflow after variant selection and filtration.

### Alignment Metrics

The alignment metrics provide information about the quality and characteristics of the read alignment.

### Insert-Size Metrics

The insert-size metrics provide information about the sequencing library fragment-size distribution.

The `finalvcf_metrics/` folder is intended to provide a concise set of representative final outputs for review without requiring users to inspect every intermediate result generated by the workflow.

> **Important:** These example outputs were generated using the reduced 10,000-read test dataset. Coverage, depth, alignment statistics, and variant counts should therefore be interpreted as pipeline-validation results rather than representative results from the complete WES dataset.

---

## Intermediate File Management

During execution, **Nextflow DSL2 automatically creates the `work/` directory** to store intermediate files generated by individual processes.

The `work/` directory contains process-specific intermediate files and execution data used by Nextflow during workflow execution and caching.

The pipeline organizes persistent process outputs separately under:

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

This structure allows individual process outputs to be inspected while keeping the final demonstration outputs separately organized.

The `work/` directory is required during pipeline execution and can consume substantial disk space.

After successful pipeline completion and verification of the required outputs, the `work/` directory can be removed when the intermediate files are no longer required.

The `work/` directory is not included in the GitHub repository.

Essential final outputs and QC/metrics are retained in the `results/` directory, while selected outputs are additionally provided in `finalvcf_metrics/`.

---

## Important Notes

### Reduced Test Dataset

The pipeline was tested using only **10,000 reads per paired-end FASTQ file** because the complete WES dataset required more RAM and computational resources than were available in the local WSL environment.

### Coverage and Depth

Because the test dataset contains only 10,000 reads per read pair, the resulting coverage and sequencing depth are expected to be substantially lower than those obtained from the complete WES dataset.

As a result, the final VCF may contain fewer variants than expected from a full WES analysis.

### Reference Genome Compatibility

The pipeline uses:

```text
GRCh38 / hg38
```

The following must correspond to the same genome assembly:

- Reference genome
- BWA indexes
- FASTA index
- GATK sequence dictionary
- WES target BED file

### Reference Preparation

Reference indexing and dictionary generation were performed separately and are not included as processes in the current workflow.

This avoids repeating computationally intensive reference preparation during every pipeline execution.

### Large Files

The following are intentionally not included in the GitHub repository:

- Original full-size FASTQ files
- Reference genome
- Reference genome indexes
- Nextflow `work/` directory
- Large intermediate files

These files must be prepared locally before running the pipeline.

---

## Reproducibility

This project uses **Nextflow DSL2** and a modular workflow architecture.

Individual analysis steps are implemented as separate Nextflow modules:

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

Reproducibility is supported through:

- Nextflow DSL2 workflow orchestration
- Modular process design
- Version-controlled source code using Git/GitHub
- Documented software versions
- Centralized pipeline configuration
- Defined reference genome and target BED requirements
- Documented test dataset preparation
- Separate organization of process outputs

The pipeline can be executed consistently across samples provided that the required input files, reference files, target BED file, software environment, and configuration are appropriately prepared.

---

## Limitations

This pipeline was developed and tested in a resource-limited local WSL environment.

The 10,000-read dataset was used specifically to validate the workflow while reducing computational requirements.

Therefore, the current test results should not be considered representative of a complete WES analysis.

For full-scale WES analysis, the complete sequencing dataset should be processed using an environment with adequate CPU, RAM, storage, and computational resources.

The workflow should be appropriately validated before use in research or clinical production environments.

---


## Disclaimer

This pipeline is intended for **bioinformatics workflow development, testing, and demonstration purposes**.

The reduced test dataset and example outputs are provided to demonstrate workflow execution and should not be used as a substitute for a complete WES analysis or clinical interpretation.
