process CONCAT_READ_IDS {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(read_id_files, stageAs: 'inputs/*')

    output:
    tuple val(meta), path("${meta.id}_atac_read_ids.txt"), emit: read_ids

    script:
    """
    cat ${read_id_files} | sort -u > ${meta.id}_atac_read_ids.txt
    """

    stub:
    """
    touch ${meta.id}_atac_read_ids.txt
    """
}
