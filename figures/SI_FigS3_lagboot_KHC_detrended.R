# =============================================================================
# SI_FigS3_lagboot_KHC_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS3_lagboot_KHC_detrended.png and .pdf
# What   : Supplement Fig. S3. Per-lag pairs-bootstrap 95% interval of the cross-correlation, KHC (detrended).
# Inputs : A13_lagboot_detrended
# Run from pub_code/:  Rscript figures/SI_FigS3_lagboot_KHC_detrended.R
# =============================================================================
source("lib/pub_setup.R")

cave <- "KHC"
lb <- read_analysis("A13_lagboot_detrended") %>%
  mutate(pair_label = factor(Pair, levels = all_pair_levels))
n_pairs <- n_distinct(lb$Pair[lb$Cave == cave])

g <- plot_lagboot(lb, cave, "detrended")

save_figure(g, "SI_FigS3_lagboot_KHC_detrended", width = 9.5, height = facet_h(ceiling(n_pairs / 2)))
