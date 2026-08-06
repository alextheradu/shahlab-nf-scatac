#!/usr/bin/env Rscript
# Runs ArchR's createArrowFiles on a bgzipped+tabix-indexed fragments file,
# which produces the two QC PDFs as a side effect, then exports the
# per-cell metadata to CSV for the interactive HTML report.

args <- commandArgs(trailingOnly = TRUE)
fragments_file <- args[1]
sample_name    <- args[2]

library(ArchR)
addArchRGenome("hg19")

arrow_file <- createArrowFiles(
  inputFiles = fragments_file,
  sampleNames = sample_name,
  outputNames = sample_name,
  minTSS = 0,
  minFrags = 0,
  addTileMat = FALSE,
  addGeneScoreMat = FALSE
)

metadata_rds <- file.path(
  "QualityControl", sample_name,
  paste0(sample_name, "-Pre-Filter-Metadata.rds")
)
df <- readRDS(metadata_rds)
write.csv(as.data.frame(df), paste0(sample_name, "_percell_metrics.csv"), row.names = FALSE)

cat("Done.\n")
