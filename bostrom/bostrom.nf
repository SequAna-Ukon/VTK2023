#!/usr/bin/env nextflow

/*
example code associated with the analysis of the Böstrom dataset for the 2023 VTK
*/

nextflow.enable.dsl=2

samples_ch = Channel.fromFilePairs("./raw_reads/fastq/*.fastq.gz", size: 1).map{[it[0], it[1][0]]}

process fastp {
    tag "${sample}"
    conda "fastp -c bioconda"
    publishDir "./fastp/", mode: "copy"
    input:
    tuple val(sample), path(read_1)

    output:
    file("${sample}.fastp.html")
    tuple val(sample), file("${sample}.clean.fq.gz")

    script:
    """
    fastp -q 20 -i $read_1 -o ${sample}.clean.fq.gz
    mv fastp.html ${sample}.fastp.html
    """
}

workflow {
    input_ch = samples_ch
    fastp(input_ch)
}

