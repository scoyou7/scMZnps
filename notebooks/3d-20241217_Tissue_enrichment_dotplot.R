#!/usr/bin/Rscript
# --------------------------------------------------------------------------
# Make plots for scMZNOS analysis
# --------------------------------------------------------------------------

# Set working directory
setwd("/home/scott/Sync/scmznos_sync/")  # Adjust path if running locally

# Set random seed for reproducibility
set.seed(42)

# Define synchronization directory for input files
sync_dir <- '~/Sync/scmznos_sync/'

# Load required libraries
library(dplyr)      # Data manipulation
library(ggplot2)    # Visualization

# --------------------------------------------------------------------------
# Aggregate Tissue Enrichment Data Across KO Clusters
# --------------------------------------------------------------------------

# Initialize a loop to read tissue enrichment files for each KO cluster
for (i in 1:5) {
  # Read enrichment data for the current KO cluster
  tmp_enriched <- read.csv(
    paste0(sync_dir, "Tissue_KO_clusters/Tissue_Marker_Enrichment_Tissue_KO_clusters_KO ", i, ".csv"),
    row.names = 1
  )[, c('Term', 'Adjusted.P.value', 'Odds.Ratio')]
  
  # Order terms by name for consistency
  tmp_enriched <- tmp_enriched[order(tmp_enriched$Term, decreasing = TRUE), ]
  tmp_enriched[, 'Sample'] <- paste0('KO ', i)  # Add cluster identifier
  
  # Combine data across KO clusters
  if (i == 1) {
    Tissue_enriched <- tmp_enriched
  } else {
    Tissue_enriched <- rbind(Tissue_enriched, tmp_enriched)
  }
}

# --------------------------------------------------------------------------
# Filter and Transform Data for Visualization
# --------------------------------------------------------------------------

# Extract unique significant tissue terms
sig_tissue <- sort(unique(Tissue_enriched$Term))

# Filter data to include only significant tissue terms
Tissue_enriched <- Tissue_enriched[Tissue_enriched$Term %in% sig_tissue, ]

# Remove values with non-significant adjusted p-values
Tissue_enriched$Odds.Ratio[Tissue_enriched$Adjusted.P.value > 0.01] <- NA

# Add a log10-transformed p-value column
Tissue_enriched[, 'log10pval'] <- -log10(Tissue_enriched$Adjusted.P.value)

# Create a matrix of p-values for hierarchical clustering
pval <- reshape(
  Tissue_enriched[, c("Sample", 'Term', 'log10pval')],
  idvar = "Term", timevar = "Sample", direction = "wide"
)
colnames(pval) <- gsub('log10pval.', '', colnames(pval))

# --------------------------------------------------------------------------
# Define Custom Order for Tissues (hc_order)
# --------------------------------------------------------------------------

# Manually specify the desired order of tissue terms
sig_order <- c(
  'Epidermal', 'Ectoderm', 'Notochord', 'Prechordal plate', 'Epidermal-early',
  'Tailbud', 'Cardiac', 'Neural-early', 'Forebrain', 'Mid-Hindbrain boundary',
  'Eye', 'Neural-late', 'Neural crest', 'Pharyngeal arch', 'Motoneurons',
  'Peripheral neurons', 'PGCs'
)

# Append remaining terms not in `sig_order`
hc_order <- c(sig_order, sig_tissue[!(sig_tissue %in% sig_order)])

# --------------------------------------------------------------------------
# Plot Tissue Enrichment Heatmap
# --------------------------------------------------------------------------

# Generate a dot plot showing tissue enrichment
Tissue_enriched %>%
  mutate(
    Sample = factor(Sample, levels = c('KO 1', 'KO 2', 'KO 3', 'KO 4', 'KO 5')),  # Order samples
    Term = factor(Term, levels = rev(hc_order))  # Reverse custom order for y-axis
  ) %>%
  ggplot(aes(y = Term, x = Sample)) +
  geom_point(aes(color = -log10(Adjusted.P.value), size = Odds.Ratio)) +  # Map color and size to p-values and odds ratios
  theme_classic() +  # Clean plot theme
  scale_size_continuous(range = c(1, 8)) +  # Adjust dot size range
  scale_color_gradientn(
    colours = hcl.colors(10, palette = "Pink", rev = TRUE),  # Gradient colors
    na.value = "grey80",  # Color for NA values
    values = c(0, 0.01, 0.02, 0.04, 0.06, 0.08, 0.1, 0.12, 0.14, 0.2, 0.25, 0.3, 1)  # Control gradient distribution
  ) +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),  # Rotate x-axis labels
    aspect.ratio = 4  # Set aspect ratio for readability
  ) 

# Uncomment the following lines to save the plot as a PDF
# ggsave("Tissue_enrichment_doptplot.pdf", width = 20, height = 20, units = "cm")
# ggsave("Tissue_enrichment_doptplot_all_tissues.pdf")
