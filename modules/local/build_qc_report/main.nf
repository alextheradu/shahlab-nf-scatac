process BUILD_QC_REPORT {
    tag "${meta.id}"
    label 'process_low'
    // Rebuild the image with scripts/build_wave_containers.py after editing environment.yml.
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/c0/c0e61794e23fb37dd01134b3ecd61531656813f27f291c7101cfdc291c3a4441/data'
        : 'community.wave.seqera.io/library/python_pandas_numpy_plotly:c4a638ecff2d8d8b'}"

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
