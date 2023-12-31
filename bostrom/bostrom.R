# All R code associated with the processing of the böstrom data
library(dplyr)
library(tidyverse)
library(GenomicFeatures)
library(RMariaDB)
library(stringr)
library(tximport)
library(DESeq2)
library(pheatmap)
library(vsn)
library(matrixStats)

# Create a tx2gene file that is compatible with the reference genome
txdb <- makeTxDbFromEnsembl("Homo sapiens", release=107)
k <- keys(txdb, keytype = "TXNAME")
tx2gene <- AnnotationDbi::select(txdb, k, "GENEID", "TXNAME")
head(tx2gene)


# Load the meta information sample dataframe

# For GitPod
# samples = read.csv("/workspace/VTK2023/bostrom_meta.csv", header=TRUE)

# For execution locally
samples = read.csv("bostrom_meta.csv", header=TRUE)

# Set cell_type, cell_cycle_stage and rep columns as factors
samples = samples %>% mutate(cell_type = as.factor(cell_type), cell_cycle_stage = as.factor(cell_cycle_stage), rep = as.factor(rep))

# Make a vector that contains the full paths to the abundance.h5 files

# For GitPod
# kallisto.base.dir = "/home/gitpod/kallisto_out"
kallisto.base.dir = "kallisto_out"

# For execution locally
files <- file.path(kallisto.base.dir, samples$dir_name, "abundance.h5")

# Verify that all the files are there
all(file.exists(files))
file.exists(files)

# Create sample names based on the meta info
samples$sample_name = stringr::str_c(samples$dir_name, "_", samples$cell_type, "_", samples$cell_cycle_stage, "_", samples$rep)
names(files) <- samples$sample_name
rownames(samples) = samples$sample_name

# Finally we can use tximport to read in the abundance tables
# and perform the normalizations
txi = tximport(files, type = "kallisto", tx2gene = tx2gene)

# Create the DESEQ2 object
dds = DESeqDataSetFromTximport(txi, colData = samples, design = ~ cell_cycle_stage)

# Fit the model and run the DE analysis
dds = DESeq(dds)

# take a look at the results table
res = results(dds)
res_ordered = res[order(res$log2FoldChange),]

# Take a look at the other result names available 
resultsNames(dds)
alt_res <- results(dds, contrast=c("cell_cycle_stage", "G2", "G1"))

res_ordered_p_val <- res[order(res$padj),]
head(res_ordered_p_val)

# Let's perform the shrinkage so that we can see what effect it has.
resLFC <- lfcShrink(dds, coef="cell_cycle_stage_S_vs_G1", type="apeglm")

# Let's compare the shrinkage results
plotMA(res, ylim=c(-2,2))
ggsave("res_MA.png")
plotMA(resLFC, ylim=c(-2,2))

# Two forms of normalization to do the plotting with
vsd <- vst(dds, blind=FALSE)
rld <- rlog(dds, blind=FALSE)
ntd <- normTransform(dds)

# Let's say we're only interested in those genes that were differentially expressed between one of the
# 3 comparisons
# We can generate a list of these genes
s1_g1_sig_res = as.data.frame(results(dds, contrast=c("cell_cycle_stage", "S", "G1"))) %>% dplyr::filter(padj <= 0.01)
dim(s1_g1_sig_res)
s1_g2_sig_res = as.data.frame(results(dds, contrast=c("cell_cycle_stage", "S", "G2"))) %>% dplyr::filter(padj <= 0.01)
dim(s1_g2_sig_res)
g1_g2_sig_res = as.data.frame(results(dds, contrast=c("cell_cycle_stage", "G1", "G2"))) %>% dplyr::filter(padj <= 0.01)
dim(g1_g2_sig_res)

sig_genes_redundant = c(rownames(s1_g1_sig_res), rownames(s1_g2_sig_res), rownames(g1_g2_sig_res))
length(sig_genes_redundant) # 4129
sig_genes_unique = unique(sig_genes_redundant)
length(sig_genes_unique) # 2677


# Next we need to make a df where we have the average count by cell_cycle_stage
dds_counts = as.data.frame(assay(dds))
dds_counts_w_av = dds_counts %>% dplyr::mutate(
    s_av=rowMeans(dplyr::select(., c(SRR6150372_HeLa_S_1, SRR6150373_HeLa_S_2, SRR6150374_HeLa_S_3))),
    g1_av=rowMeans(dplyr::select(., c(SRR6150369_HeLa_G1_1, SRR6150370_HeLa_G1_2, SRR6150371_HeLa_G1_3))),
    g2_av=rowMeans(dplyr::select(., c(SRR6150375_HeLa_G2_1, SRR6150378_HeLa_G2_2, SRR6150381_HeLa_G2_3)))
    )

# Finally we want to filter down to just the average columns
dds_counts_only_av = dds_counts_w_av %>% dplyr::select(c(s_av, g1_av, g2_av))
dds_counts_only_av_sig = dds_counts_only_av[sig_genes_unique,]

# We can plot the genes in order of abundance
# but first we will want to normalize the data by row so that we can pre-order by post
# normalized abundance.

# Plot it up without normalization first.
head(dds_counts_only_av_sig)
dds_counts_only_av_sig_s1_ordered = dds_counts_only_av_sig[order(dds_counts_only_av_sig$s_av, decreasing = T),]
pheatmap(dds_counts_only_av_sig_s1_ordered[1:10,],cluster_rows=FALSE, show_rownames=FALSE, cluster_cols=FALSE)


# We need to standardize the data by row and then order and then plot
RowSD <- function(x) {
  sqrt(rowSums((x - rowMeans(x))^2)/(dim(x)[2] - 1))
}

# Create columns of the mean and standard deviation
dds_counts_only_av_sig_stand = dds_counts_only_av_sig %>% 
  mutate(mean = (s_av + g1_av + g2_av)/3, stdev = RowSD(cbind(s_av, g1_av, g2_av)))

# Finally normalise the averages.
dds_counts_standardized = dds_counts_only_av_sig_stand %>% mutate(
    s_std = (s_av-mean)/stdev,
    g1_std = (g1_av-mean)/stdev,
    g2_std = (g2_av-mean)/stdev
    ) %>% dplyr::select(s_std, g1_std, g2_std) %>% arrange(desc(s_std))

# Then plot the heat map.
pheatmap(dds_counts_standardized, cluster_rows=FALSE, show_rownames=FALSE, cluster_cols=FALSE)
