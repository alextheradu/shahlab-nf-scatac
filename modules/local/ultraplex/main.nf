process ULTRAPLEX {
    tag "${meta.id}"
    label 'process_medium'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/ultraplex:1.2.9--py39hff71179_2'
        : 'quay.io/biocontainers/ultraplex:1.2.9--py39hff71179_2'}"

    input:
    tuple val(meta), path(fastq_r2)
    path barcodes_csv
    val adapter
    val adapter2

    output:
    tuple val(meta), path("ultraplex_demux_ATAC.fastq.gz")        , emit: atac
    tuple val(meta), path("ultraplex_demux_WGS.fastq.gz")         , emit: wgs
    tuple val(meta), path("ultraplex_demux_5bc_no_match.fastq.gz"), emit: nomatch

    script:
    """
    ultraplex \\
        -i ${fastq_r2} \\
        -b ${barcodes_csv} \\
        -q 0 --fiveprimemismatches 3 \\
        --adapter ${adapter} \\
        --adapter2 ${adapter2} \\
        --directory .

    for f in ultraplex_demux_ATAC.fastq.gz ultraplex_demux_WGS.fastq.gz ultraplex_demux_5bc_no_match.fastq.gz; do
        if [[ ! -f "\$f" ]]; then
            echo -n | gzip > "\$f"
        fi
    done
    """

    stub:
    """
    touch ultraplex_demux_ATAC.fastq.gz
    touch ultraplex_demux_WGS.fastq.gz
    touch ultraplex_demux_5bc_no_match.fastq.gz
    """
}
