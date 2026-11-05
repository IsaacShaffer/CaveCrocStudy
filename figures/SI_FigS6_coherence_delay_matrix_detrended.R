# =============================================================================
# SI_FigS6_coherence_delay_matrix_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS6_coherence_delay_matrix_detrended.png and .pdf
# What   : Supplement Fig. S6. Directed coherence peak-delay matrix, Croc-2 (left) and KHC (right), detrended.
# Inputs : A08_coherence_summary_detrended
# Run from pub_code/:  Rscript figures/SI_FigS6_coherence_delay_matrix_detrended.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A08_coherence_summary_detrended")
panel <- function(cave) plot_pair_matrix(tbl, cave, "delay_at_peak_hr", "Delay (h)", signed = TRUE)

g <- panel("Croc-2") | panel("KHC")

save_figure(g, "SI_FigS6_coherence_delay_matrix_detrended", width = 12, height = 5.2)
