process BUILD_QC_REPORT {
    tag "${meta.id}"
    label 'process_low'
    conda "/home/radua/.conda/envs/snapatac2-env"

    input:
    tuple val(meta), path(percell_csv), path(fragments), path(fragments_tbi)

    output:
    tuple val(meta), path("${meta.id}_qc_report.html"), emit: report

    script:
    """
    build_interactive_qc.py \\
        --percell-csv ${percell_csv} \\
        --fragments ${fragments} \\
        --sample-name ${meta.id} \\
        --output ${meta.id}_qc_report.html
    """

    stub:
    """
    touch ${meta.id}_qc_report.html
    """
}
