process EXTRACT_ATAC_READ_IDS {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(atac_fastq)

    output:
    tuple val(meta), path("atac_read_ids.txt"), emit: read_ids

    script:
    """
    zcat ${atac_fastq} | awk 'NR % 4 == 1 {name=substr(\$1, 2); split(name, a, "_"); print a[1]}' > atac_read_ids.txt
    """

    stub:
    """
    touch atac_read_ids.txt
    """
}