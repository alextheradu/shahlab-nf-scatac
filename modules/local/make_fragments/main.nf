process MAKE_FRAGMENTS {
    tag "${meta.id}"
    label 'process_medium'
    conda "/home/radua/.conda/envs/snapatac2-env"

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
