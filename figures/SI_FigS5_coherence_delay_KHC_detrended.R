# =============================================================================
# SI_FigS5_coherence_delay_KHC_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS5_coherence_delay_KHC_detrended.png and .pdf
# What   : Supplement Fig. S5. Phase-derived delay versus period, one panel per pair, KHC (detrended).
# Inputs : A09_coherence_spectra_detrended
# Run from pub_code/:  Rscript figures/SI_FigS5_coherence_delay_KHC_detrended.R
# =============================================================================
source("lib/pub_setup.R")

cave <- "KHC"
sp <- read_analysis("A09_coherence_spectra_detrended") %>%
  mutate(pair_label = factor(Pair, levels = all_pair_levels))
n_pairs <- n_distinct(sp$Pair[sp$Cave == cave])

g <- plot_coh_metric(sp, cave, "delay")

save_figure(g, "SI_FigS5_coherence_delay_KHC_detrended", width = 9.5, height = facet_h(ceiling(n_pairs / 2)))
