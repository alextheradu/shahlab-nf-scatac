process BGZIP_FRAGMENTS {
    tag "${meta.id}"
    label 'process_low'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8c/8c5d2818c8b9f58e1fba77ce219fdaf32087ae53e857c4a496402978af26e78c/data'
        : 'community.wave.seqera.io/library/htslib_samtools:1.23.1--5b6bb4ede7e612e5'}"

    input:
    tuple val(meta), path(fragments)

    output:
    tuple val(meta), path("${meta.id}_fragments.sorted.tsv.gz"), path("${meta.id}_fragments.sorted.tsv.gz.tbi"), emit: fragments_indexed

    script:
    """
    zcat ${fragments} | sort -k1,1 -k2,2n > fragments.sorted.tsv
    bgzip -f fragments.sorted.tsv
    mv fragments.sorted.tsv.gz ${meta.id}_fragments.sorted.tsv.gz
    tabix -p bed ${meta.id}_fragments.sorted.tsv.gz
    """

    stub:
    """
    touch ${meta.id}_fragments.sorted.tsv.gz
    touch ${meta.id}_fragments.sorted.tsv.gz.tbi
    """
}
