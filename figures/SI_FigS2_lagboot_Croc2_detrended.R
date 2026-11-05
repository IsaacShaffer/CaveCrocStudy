# =============================================================================
# SI_FigS2_lagboot_Croc2_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS2_lagboot_Croc2_detrended.png and .pdf
# What   : Supplement Fig. S2. Per-lag pairs-bootstrap 95% interval of the cross-correlation, Croc-2 (detrended).
# Inputs : A13_lagboot_detrended
# Run from pub_code/:  Rscript figures/SI_FigS2_lagboot_Croc2_detrended.R
# =============================================================================
source("lib/pub_setup.R")

cave <- "Croc-2"
lb <- read_analysis("A13_lagboot_detrended") %>%
  mutate(pair_label = factor(Pair, levels = all_pair_levels))
n_pairs <- n_distinct(lb$Pair[lb$Cave == cave])

g <- plot_lagboot(lb, cave, "detrended")

save_figure(g, "SI_FigS2_lagboot_Croc2_detrended", width = 9.5, height = facet_h(ceiling(n_pairs / 2)))
