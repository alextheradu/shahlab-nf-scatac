process FILTER_BAM {
    tag "${meta.id}"
    label 'process_medium'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8c/8c5d2818c8b9f58e1fba77ce219fdaf32087ae53e857c4a496402978af26e78c/data'
        : 'community.wave.seqera.io/library/htslib_samtools:1.23.1--5b6bb4ede7e612e5'}"

    input:
    tuple val(meta), path(markdup_bam), path(read_ids)

    output:
    tuple val(meta), path("${meta.id}_atac_filtered.bam"), emit: bam

    script:
    """
    samtools view -h -N ${read_ids} -@ ${task.cpus} -b ${markdup_bam} > ${meta.id}_atac_filtered.bam
    """

    stub:
    """
    touch ${meta.id}_atac_filtered.bam
    """
}
