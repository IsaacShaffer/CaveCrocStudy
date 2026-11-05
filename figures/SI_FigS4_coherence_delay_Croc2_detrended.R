# =============================================================================
# SI_FigS4_coherence_delay_Croc2_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS4_coherence_delay_Croc2_detrended.png and .pdf
# What   : Supplement Fig. S4. Phase-derived delay versus period, one panel per pair, Croc-2 (detrended).
# Inputs : A09_coherence_spectra_detrended
# Run from pub_code/:  Rscript figures/SI_FigS4_coherence_delay_Croc2_detrended.R
# =============================================================================
source("lib/pub_setup.R")

cave <- "Croc-2"
sp <- read_analysis("A09_coherence_spectra_detrended") %>%
  mutate(pair_label = factor(Pair, levels = all_pair_levels))
n_pairs <- n_distinct(sp$Pair[sp$Cave == cave])

g <- plot_coh_metric(sp, cave, "delay")

save_figure(g, "SI_FigS4_coherence_delay_Croc2_detrended", width = 9.5, height = facet_h(ceiling(n_pairs / 2)))
