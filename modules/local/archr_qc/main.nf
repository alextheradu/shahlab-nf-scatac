process ARCHR_QC {
    tag "${meta.id}"
    label 'process_high'
    // ArchR plus the hg19 annotation packages that addArchRGenome("hg19") needs;
    // the stock r-archr biocontainer ships without them. Rebuild the image with
    // scripts/build_wave_containers.py after editing environment.yml.
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/16/16b4da322f80a0c0c8b13e4c804d10d4cd902871ddd8a09920d52e5c8493a026/data'
        : 'community.wave.seqera.io/library/r-archr_bioconductor-bsgenome.hsapiens.ucsc.hg19_bioconductor-txdb.hsapiens.ucsc.hg19.knowngene_bioconductor-org.hs.eg.db:1af2da1ed939ee95'}"

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
