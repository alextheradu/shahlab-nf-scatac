process BUILD_QC_REPORT {
    tag "${meta.id}"
    label 'process_low'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/9d/9d94011e47cab0aa6f110628e297492dfa6d579fa1825419c105e8b86df86d24/data'
        : 'community.wave.seqera.io/library/python_pandas_numpy_plotly:f55fe0ba15990737'}"

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
