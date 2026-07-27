process ULTRAPLEX {
    tag "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(fastq_r2)
    val barcodes_csv
    val ultraplex_sif
    val adapter
    val adapter2
    val bind_paths

    output:
    tuple val(meta), path("ultraplex_demux_ATAC.fastq.gz")        , emit: atac
    tuple val(meta), path("ultraplex_demux_WGS.fastq.gz")         , emit: wgs
    tuple val(meta), path("ultraplex_demux_5bc_no_match.fastq.gz"), emit: nomatch

    script:
    def binds = bind_paths.split(',').collect { "-B ${it}" }.join(' ')
    """
    singularity run --no-home ${binds} ${ultraplex_sif} ultraplex \\
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
}
