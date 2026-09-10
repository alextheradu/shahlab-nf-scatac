process EXTRACT_ATAC_READ_IDS {
    tag "${meta.id}"
    label 'process_low'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8c/8c5d2818c8b9f58e1fba77ce219fdaf32087ae53e857c4a496402978af26e78c/data'
        : 'community.wave.seqera.io/library/htslib_samtools:1.23.1--5b6bb4ede7e612e5'}"

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