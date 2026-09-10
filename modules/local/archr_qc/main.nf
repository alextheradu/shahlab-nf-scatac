process ARCHR_QC {
    tag "${meta.id}"
    label 'process_high'
    // ArchR plus the hg19 annotation packages that addArchRGenome("hg19") needs;
    // the stock r-archr biocontainer ships without them.
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ba/ba1187b757ad078658207995f4f1d3be4aee78b217a692b89c50e19ac57fb149/data'
        : 'community.wave.seqera.io/library/r-archr_bioconductor-bsgenome.hsapiens.ucsc.hg19_bioconductor-txdb.hsapiens.ucsc.hg19.knowngene_bioconductor-org.hs.eg.db:54e6e9397975c3c3'}"

    input:
    tuple val(meta), path(fragments), path(fragments_tbi)

    output:
    tuple val(meta), path("QualityControl/${meta.id}/*-Fragment_Size_Distribution.pdf"), emit: fragment_size_pdf
    tuple val(meta), path("QualityControl/${meta.id}/*-TSS_by_Unique_Frags.pdf"), emit: tss_pdf
    tuple val(meta), path("${meta.id}_percell_metrics.csv"), emit: percell_csv

    script:
    """
    run_archr_qc.R ${fragments} ${meta.id}
    """

    stub:
    """
    mkdir -p QualityControl/${meta.id}
    touch QualityControl/${meta.id}/${meta.id}-Fragment_Size_Distribution.pdf
    touch QualityControl/${meta.id}/${meta.id}-TSS_by_Unique_Frags.pdf
    touch ${meta.id}_percell_metrics.csv
    """
}
