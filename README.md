# Nextflow WES Variant Calling Pipeline

A reproducible **Whole Exome Sequencing (WES) variant-calling pipeline** developed using **Nextflow DSL2**. The workflow processes paired-end FASTQ files through quality control, read alignment, duplicate marking, alignment metrics, germline variant calling, and variant filtration.

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
- [Input Requirements](#input-requirements)
- [Running the Pipeline](#running-the-pipeline)
- [Pipeline Steps](#pipeline-steps)
- [Important Notes](#important-notes)
- [Reproducibility](#reproducibility)

---

## Project Overview

This project implements a modular WES analysis workflow using **Nextflow DSL2**.

The pipeline is designed to process paired-end WES sequencing data and perform:

- Raw-read quality control
- QC report aggregation
- Reference genome alignment
- Duplicate marking
- BAM sorting and processing
- Alignment metrics
- Insert-size metrics
- Germline variant calling
- Variant selection
- Variant filtration
- PASS variant selection

The workflow is organized into independent Nextflow modules to make the pipeline easier to maintain, test, and reuse.

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
                Mark Duplicates
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
      Alignment Metrics     Insert Size Metrics
              │                   │
              └─────────┬─────────┘
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
                 Final VCF Output
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

The reference genome was subsequently indexed and prepared for use with BWA, SAMtools, and GATK.

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

Example:

```text
data/
├── test_R1.fastq.gz
└── test_R2.fastq.gz
```

### Purpose of the Reduced Dataset

The reduced dataset was used for:

- Pipeline development
- Workflow testing
- Process validation
- Nextflow module integration
- End-to-end pipeline execution

### Important Limitation

Because the test dataset contains only **10,000 reads**, the sequencing depth and coverage are substantially lower than those expected from the complete WES dataset.

Therefore:

> The resulting coverage, depth, and variant counts should not be interpreted as representative of the complete HG001 WES dataset.

For production or research-grade analysis, the complete sequencing dataset should be processed using sufficient computational resources.

---

## Reference Genome Preparation

The reference genome was prepared separately before running the workflow.

The following files were generated and required for the pipeline:

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

This generated the BWA index files:

```text
hg38.fa.amb
hg38.fa.ann
hg38.fa.bwt
hg38.fa.pac
hg38.fa.sa
```

### SAMtools FASTA Index

A FASTA index was generated using:

```bash
samtools faidx hg38.fa
```

This generated:

```text
hg38.fa.fai
```

### GATK Sequence Dictionary

A GATK-compatible sequence dictionary was generated using:

```bash
gatk CreateSequenceDictionary -R hg38.fa
```

This generated:

```text
hg38.dict
```

### Why Reference Preparation Is Not Included in the Workflow

Reference indexing is a one-time preparation step and can require considerable computational resources.

To reduce unnecessary processing time during pipeline execution, the reference genome and all required index files were prepared separately.

The current Nextflow workflow therefore starts from an already-prepared reference genome and proceeds directly to the alignment stage.

**Before running the pipeline, ensure that all required files are present in the `reference/` directory.**

---

## Environment and Software Versions

The pipeline was developed and tested in a **Miniconda environment** on Linux/WSL.

### Conda Environment

Create the environment:

```bash
conda create -n nextflow-wes
```

Activate it:

```bash
conda activate nextflow-wes
```

Install the required software and dependencies listed below in this environment.

### Software Versions

| Software | Version |
|---|---|
| Nextflow | 26.04.6 |
| FastQC | 0.12.1 |
| MultiQC | 1.35 |
| BWA-MEM | 0.7.19 |
| SAMtools | 1.21 |
| GATK | 4.6.2.0 |
| HTSJDK | 4.2.0 |
| Picard | 3.4.0 |

### Nextflow

```text
N E X T F L O W
version 26.04.6 build 12646
created 09-07-2026 18:49 UTC
```

The workflow is implemented using **Nextflow DSL2**.

### GATK Components

The variant-calling and variant-processing environment includes:

```text
GATK       4.6.2.0
HTSJDK     4.2.0
Picard     3.4.0
```

Documenting these versions helps maintain reproducibility across different environments.

---

## Project Structure

### Local Project Structure

The complete project used to execute the workflow contains:

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
├── main.nf
└── nextflow.config
```

### GitHub Repository Structure

Large input and reference files are **not included in this GitHub repository**.

The repository contains the workflow implementation:

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

Users must prepare the required `data/`, `bed/`, and `reference/` directories locally before running the workflow.

---

## Requirements

Before running the pipeline, ensure that the following requirements are available:

1. **Miniconda/Conda**
2. **Nextflow**
3. Required bioinformatics tools and dependencies
4. Paired-end FASTQ files
5. Compatible WES target BED file
6. GRCh38/hg38 reference genome
7. Required BWA indexes
8. FASTA index (`.fai`)
9. GATK sequence dictionary (`.dict`)

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

### Step 2: Prepare the Required Directories

The following directories should be available locally:

```text
bed/
data/
reference/
modules/
```

Along with:

```text
main.nf
nextflow.config
```

The `data/` directory should contain the paired-end FASTQ files.

The `bed/` directory should contain the appropriate WES capture BED file.

The `reference/` directory should contain the prepared hg38 reference genome and all required index files.

---

### Step 3: Verify the Reference Files

Before execution, verify that the following files are present:

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

## Running the Pipeline

From the project root directory, activate the Conda environment:

```bash
conda activate nextflow-wes
```

Run the workflow:

```bash
nextflow run main.nf
```

The workflow uses the parameters and paths defined in:

```text
nextflow.config
```

---

## Pipeline Steps

### 1. FastQC

FastQC is used to perform quality control on the input FASTQ files.

The analysis evaluates common sequencing quality metrics such as:

- Per-base sequence quality
- Sequence length
- GC content
- Adapter content
- Sequence duplication

---

### 2. MultiQC

MultiQC aggregates the quality-control reports generated by FastQC into a consolidated report.

This provides an overall view of the sequencing quality.

---

### 3. Read Alignment

Paired-end sequencing reads are aligned to the **GRCh38/hg38 reference genome** using BWA-MEM.

The pre-generated BWA indexes are used during this step.

---

### 4. Duplicate Marking and BAM Processing

Aligned reads are processed and duplicate reads are identified and marked.

BAM files are sorted and prepared for downstream variant calling.

---

### 5. Alignment Metrics

Alignment metrics are generated to assess the quality and characteristics of the sequencing alignment.

---

### 6. Insert-Size Metrics

Insert-size metrics are generated to evaluate the distribution of fragment sizes in the sequencing data.

---

### 7. Germline Variant Calling

Germline SNVs and indels are called using:

```text
GATK HaplotypeCaller
```

---

### 8. Variant Selection

Variants are separated/selected according to the required variant categories for downstream processing.

---

### 9. Variant Filtration

Quality-based filtering is applied to the called variants.

The filtering stage is used to identify variants that satisfy the configured quality criteria.

---

### 10. PASS Variant Selection

Variants that pass the configured filtering criteria are selected for the final analysis.

---

## Important Notes

### Reduced Test Dataset

This workflow was tested using a reduced dataset containing **10,000 reads per paired-end FASTQ file**.

This was done because the complete WES dataset required more computational resources than were available in the local WSL environment.

The reduced dataset is intended for **pipeline testing and demonstration**, not for generating final biological conclusions.

### Coverage and Depth

Because of the reduced number of reads, the resulting:

- Sequencing coverage
- Read depth
- Variant count

may be considerably lower than expected from the complete WES dataset.

### Reference Genome Compatibility

The reference genome, BWA indexes, FASTA index, sequence dictionary, and target BED file must be compatible with the same genome assembly.

This workflow uses:

```text
GRCh38 / hg38
```

### Reference Files

The reference genome and index files are intentionally not included in the GitHub repository because of their large file size.

They must be prepared separately before running the pipeline.

### Input Data

The original FASTQ data is also not included in the repository. Users should obtain the appropriate sequencing data independently and prepare the required input files.

---

## Reproducibility

This project uses **Nextflow DSL2** and a modular workflow architecture.

The pipeline separates individual analysis steps into independent Nextflow modules, making the workflow easier to:

- Maintain
- Test
- Reuse
- Modify
- Reproduce

The software versions used during development and testing are documented in this README.

Large sequencing files, reference genomes, generated indexes, temporary files, and analysis results are intentionally excluded from the GitHub repository.

--

## Disclaimer

This pipeline was developed for **bioinformatics workflow development, testing, and demonstration purposes**.

The reduced 10,000-read dataset used for testing is not representative of a complete WES analysis. The workflow should be appropriately validated and tested with complete datasets and suitable computational resources before being used for research or clinical applications.
