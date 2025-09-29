#!/usr/bin/Rscript
# --------------------------------------------------------------------------
# Create plots for scMZNOS donor vs. host cell type distributions
# --------------------------------------------------------------------------

# Set working directory
setwd("/home/scott/Sync/scmznos_sync/")  # Update this path if running locally

# Load required libraries
library('dplyr')       # Data manipulation
library('tidyr')       # Data tidying
library('ggplot2')     # Visualization
library('ggtext')      # Advanced text formatting for ggplot
library('readr')       # Reading CSV files
library('Matrix')      # Sparse matrices
library('ggrepel')     # Avoid overlapping text labels
library('gplots')      # Enhanced plotting functions
library('gtools')      # Miscellaneous utility functions
library('stringr')     # String manipulation
library('reshape')     # Reshaping data
library('reshape2')    # Extended reshaping capabilities
library('glue')        # String interpolation

# --------------------------------------------------------------------------
# Load and Prepare Data
# --------------------------------------------------------------------------

# Load cell percentage data
cell_pct <- read.csv(paste0('/home/scott/Sync/scmznos_sync/Cell_percentage_host_WT_confidence_interval.csv'))

# Sort data by host mean values
cell_pct <- cell_pct[order(cell_pct$Host_Mean), ]
cell_pct$Tissue_KO_clusters <- factor(cell_pct$Tissue_KO_clusters, levels = cell_pct$Tissue_KO_clusters)

# Annotate donor cells as "Above", "Below", or "Within" the 95% confidence interval
cell_pct <- cell_pct %>%
  mutate(UP_DOWN = case_when(
    Above_range_WT == 'True' ~ "Above", 
    Below_range_WT == 'True' ~ "Below",
    TRUE ~ 'Within'
  ))

# Subset percentage data and reshape for visualization
pcts <- cell_pct[, c("Mutant_A", "Mutant_B", "WT_A", "Donor_WT", "UP_DOWN", "Tissue_KO_clusters")]
pcts <- melt.data.frame(pcts)  # Reshape from wide to long format
pcts[,'Source'] <- ifelse(grepl('Donor', pcts$variable), 'Donor', 'Host')

# Extract host mean and confidence intervals
MCI <- cell_pct[, c("Host_Mean", "CI95L", "CI95U", "Tissue_KO_clusters")]
MCI$Zero_cross <- MCI$CI95L < 0  # Flag cases where confidence intervals cross zero

# --------------------------------------------------------------------------
# Define Colors
# --------------------------------------------------------------------------

# Define colors for donor vs. host and significant intervals
binary_cols <- c('Above'='red', 'Within'='grey20', 'Below'='blue', 'TRUE'='red', 'FALSE'='grey20')

# Assign specific colors to tissues
tissue_cols <- c(
  'Axial' = '#006fa6', 'Cardiac' = '#a30059', 'Cartilage' = '#ffdbe5',
  'Ectoderm' = '#7a4900', 'Endoderm' = '#0000a6', 'Enveloping layer' = '#63ffac',
  'Ependymal' = '#b79762', 'Epidermal' = '#004d43', 'Epidermal-early' = '#8fb0ff',
  'Epidermal-late' = '#997d87', 'Eye' = '#5a0007', 'Forebrain' = '#809693',
  'Haematopoietic' = '#6a3a4c', 'Mid-Hindbrain boundary' = '#1b4400',
  'Motoneurons' = '#4fc601', 'Muscle' = '#3b5dff', 'Neural crest' = '#4a3b53',
  'Neural-early' = '#ff2f80', 'Neural-late' = '#61615a', 'Notochord' = '#ba0900',
  'PGCs' = '#6b7900', 'Paraxial mesoderm' = '#00c2a0', 'Peripheral neurons' = '#ffaa92',
  'Pharyngeal arch' = '#ff90c9', 'Prechordal plate' = '#b903aa', 'Somites' = '#d16100',
  'Tailbud' = '#82d4f7', 'Vascular' = '#000035'
)

# Annotate tissues with their corresponding colors
MCI <- MCI %>%
  mutate(
    color = tissue_cols[as.character(Tissue_KO_clusters)],  # Assign colors
    name = glue("<span style='color:{color}'>{Tissue_KO_clusters}</span>")  # Add HTML formatting
  )
MCI$name <- factor(MCI$name, levels = MCI$name)  # Set factor levels for consistent order

pcts <- pcts %>%
  mutate(
    color = tissue_cols[as.character(Tissue_KO_clusters)],
    name = glue("<span style='color:{color}'>{Tissue_KO_clusters}</span>")
  )
pcts$name <- factor(pcts$name, levels = MCI$name)

# --------------------------------------------------------------------------
# Create the Plot
# --------------------------------------------------------------------------

# Construct the plot comparing donor and host tissue percentages
ggplot() +
  geom_hline(yintercept = 0, linetype = 'dashed') +  # Add reference line at y=0
  geom_errorbar(
    data = MCI, aes(x = name, ymin = CI95L, ymax = CI95U, width = 0.2, color = Zero_cross)
  ) +  # Add error bars for host confidence intervals
  geom_point(
    data = MCI, aes(x = name, y = Host_Mean, color = Zero_cross),
    shape = "|", size = 3
  ) +  # Add host mean points
  geom_point(
    data = pcts[pcts$Source == 'Donor',],
    aes(x = name, y = value, color = UP_DOWN),
    size = 2, alpha = 0.5
  ) +  # Add donor points
  xlab('Tissue') +  # X-axis label
  ylab('Cell %') +  # Y-axis label
  scale_color_manual(values = binary_cols) +  # Use predefined color scale
  theme_classic() +  # Apply classic theme
  theme(
    axis.text.x = element_text(colour = 'black'),  # X-axis text color
    axis.text.y = element_markdown(),             # Enable colored text for Y-axis
    legend.position = "none",                     # Remove legend
    aspect.ratio = 2                              # Adjust aspect ratio
  ) +
  coord_flip()  # Flip coordinates for easier reading

# Save the plot to a PDF file
ggsave(paste0('Sample_composition_host_vs_donor.pdf'))
