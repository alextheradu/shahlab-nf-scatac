process ULTRAPLEX {
    tag "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(fastq_r2)
    val barcodes_csv
    val ultraplex_sif

    output:
    tuple val(meta), path("ultraplex_demux_ATAC.fastq.gz")       , emit: atac
    tuple val(meta), path("ultraplex_demux_WGS.fastq.gz")        , emit: wgs
    tuple val(meta), path("ultraplex_demux_5bc_no_match.fastq.gz"), emit: nomatch
    tuple val("${task.process}"), val('ultraplex'), eval("ultraplex --version 2>&1 | head -1"), emit: versions_ultraplex, topic: versions

    script:
    """
    singularity run --no-home -B /data1 -B /scratch/shahs3 ${ultraplex_sif} ultraplex \\
        -i ${fastq_r2} \\
        -b ${barcodes_csv} \\
        -q 0 --fiveprimemismatches 3 \\
        --adapter CTGTCTCTTATACACATCT \\
        --adapter2 CTGTCTCTTATACACATCTGACGCTGCCGACGA \\
        --directory .

    for f in ultraplex_demux_ATAC.fastq.gz ultraplex_demux_WGS.fastq.gz ultraplex_demux_5bc_no_match.fastq.gz; do
        if [[ ! -f "\$f" ]]; then
            echo -n | gzip > "\$f"
        fi
    done
    """

    stub:
    """
    echo -n | gzip > ultraplex_demux_ATAC.fastq.gz
    echo -n | gzip > ultraplex_demux_WGS.fastq.gz
    echo -n | gzip > ultraplex_demux_5bc_no_match.fastq.gz
    """
}
