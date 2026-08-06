process ARCHR_QC {
    tag "${meta.id}"
    label 'process_high'
    conda "/home/radua/.conda/envs/archr-env"

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
