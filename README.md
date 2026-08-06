# shahlab/demux

## Introduction

**shahlab/demux** separates ATAC and WGS reads from the DATAC single-cell co-assay: it demultiplexes raw fastqs by barcode, filters the sample's aligned BAM down to ATAC-only reads, and runs ArchR-based QC to produce an interactive HTML report (fragment size distribution, TSS enrichment) per sample.

This is a Nextflow translation of an existing Snakemake pipeline (originally written by Andrew McPherson), built following nf-core conventions.

1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Demultiplex reads by barcode into ATAC, WGS, and no-match ([`Ultraplex`](https://github.com/ulelab/ultraplex))
3. Extract ATAC read IDs per fastq
4. Merge per-fastq read IDs into one deduplicated list per sample
5. Filter the sample's aligned BAM down to ATAC-only reads
6. Index the filtered BAM ([`samtools index`](http://www.htslib.org/))
7. Convert the filtered BAM to a fragments file ([`SnapATAC2`](https://scverse.org/SnapATAC2/))
8. Sort, bgzip, and tabix-index the fragments file
9. Run ArchR QC (`createArrowFiles`) to compute per-cell TSS enrichment and fragment counts ([`ArchR`](https://www.archrproject.com/))
10. Build an interactive HTML QC report (fragment size distribution, TSS enrichment vs. unique fragments) per sample

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set up Nextflow.

First, prepare a samplesheet with your input data:

`samplesheet.csv`:

```csv
sample,fastq_r2,markdup_bam
SAMPLE1,/path/to/sample1_L001_R2.fastq.gz,/path/to/sample1_markdup.bam
SAMPLE1,/path/to/sample1_L002_R2.fastq.gz,/path/to/sample1_markdup.bam
SAMPLE2,/path/to/sample2_L001_R2.fastq.gz,/path/to/sample2_markdup.bam
```

Each row represents one R2 fastq file (one per sequencing lane). `markdup_bam` is the sample's already-aligned, duplicate-marked BAM (produced upstream by [mondrian](https://github.com/mondrian-scwgs/mondrian_nf)) — repeat the same path across every row for a given sample; the pipeline merges these lanes back together internally.

Now, you can run the pipeline using:

```bash
nextflow run shahlab/demux \
   -profile singularity,slurm \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --barcodes_csv <path/to/barcodes.csv> \
   --ultraplex_sif <path/to/ultraplex.sif>
```

`--barcodes_csv` and `--ultraplex_sif` are required — they point to the barcode reference file and the Ultraplex singularity image used for demultiplexing.

Outputs for each sample are published together under `<OUTDIR>/<sample>/`, including the filtered BAM, its index, the fragments file, ArchR's QC PDFs, and the interactive HTML report.

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/running/run-pipelines#using-parameter-files).

## Credits

shahlab/demux was originally written by Alex Radu, translating an existing Snakemake pipeline written by Andrew McPherson, with guidance from Eli Havasov.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
