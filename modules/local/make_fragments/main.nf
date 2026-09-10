process MAKE_FRAGMENTS {
    tag "${meta.id}"
    label 'process_medium'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/snapatac2:2.9.0--py312h91a5aaa_1'
        : 'quay.io/biocontainers/snapatac2:2.9.0--py312h91a5aaa_1'}"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}_fragments.tsv.gz"), emit: fragments
    tuple val(meta), path("${meta.id}_fragment_metrics.json"), emit: metrics

    script:
    """
    make_fragments.py \\
        --bam ${bam} \\
        --output ${meta.id}_fragments.tsv.gz \\
        --metrics ${meta.id}_fragment_metrics.json
    """

    stub:
    """
    touch ${meta.id}_fragments.tsv.gz
    touch ${meta.id}_fragment_metrics.json
    """
}
