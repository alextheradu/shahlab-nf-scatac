/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { SAMTOOLS_INDEX         } from '../modules/nf-core/samtools/index/main'
include { ULTRAPLEX              } from '../modules/local/ultraplex/main'
include { EXTRACT_ATAC_READ_IDS  } from '../modules/local/extract_atac_read_ids/main'
include { CONCAT_READ_IDS        } from '../modules/local/concat_read_ids/main'
include { FILTER_BAM             } from '../modules/local/filter_bam/main'
include { MAKE_FRAGMENTS         } from '../modules/local/make_fragments/main'
include { BGZIP_FRAGMENTS        } from '../modules/local/bgzip_fragments/main'
include { ARCHR_QC               } from '../modules/local/archr_qc/main'
include { BUILD_QC_REPORT        } from '../modules/local/build_qc_report/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_demux_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow DEMUX {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    outdir

    main:

    def ch_versions = channel.empty()
    //
    // MODULE: Run FastQC
    //
    ch_fastq_for_fastqc = ch_samplesheet
        .map { meta, fastq_r2, markdup_bam -> [ meta, fastq_r2 ] }

    FASTQC(ch_fastq_for_fastqc)

    //
    // MODULE: Demultiplex ATAC vs WGS reads per fastq
    //
    ch_fastq_for_ultraplex = ch_samplesheet
        .map { meta, fastq_r2, markdup_bam -> [ meta, fastq_r2 ] }

    ULTRAPLEX(
        ch_fastq_for_ultraplex,
        file(params.barcodes_csv),
        params.ultraplex_adapter,
        params.ultraplex_adapter2
    )

    //
    // MODULE: Extract read IDs from ATAC-classified reads
    //
    EXTRACT_ATAC_READ_IDS(ULTRAPLEX.out.atac)

    //
    // MODULE: Concatenate all per-fastq read ID lists into one per sample
    //
    ch_read_ids_grouped = EXTRACT_ATAC_READ_IDS.out.read_ids
        .groupTuple()

    CONCAT_READ_IDS(ch_read_ids_grouped)

    //
    // MODULE: Filter markdup BAM down to ATAC reads only
    //
    ch_markdup_bam = ch_samplesheet
        .map { meta, fastq_r2, markdup_bam -> [ meta, markdup_bam ] }
        .unique()

    ch_filter_bam_input = ch_markdup_bam
        .join(CONCAT_READ_IDS.out.read_ids)

    FILTER_BAM(ch_filter_bam_input)

    //
    // MODULE: Index the ATAC-filtered BAM
    //
    SAMTOOLS_INDEX(FILTER_BAM.out.bam)

    //
    // MODULE: Convert BAM to fragments, then run ArchR QC + build interactive report
    //
    ch_bam_for_fragments = FILTER_BAM.out.bam
        .join(SAMTOOLS_INDEX.out.index)

    MAKE_FRAGMENTS(ch_bam_for_fragments)

    BGZIP_FRAGMENTS(MAKE_FRAGMENTS.out.fragments)

    ARCHR_QC(BGZIP_FRAGMENTS.out.fragments_indexed)

    ch_report_input = ARCHR_QC.out.percell_csv
        .join(BGZIP_FRAGMENTS.out.fragments_indexed)

    BUILD_QC_REPORT(ch_report_input)

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'demux_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        )
    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
