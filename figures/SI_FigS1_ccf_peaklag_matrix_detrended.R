# =============================================================================
# SI_FigS1_ccf_peaklag_matrix_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS1_ccf_peaklag_matrix_detrended.png and .pdf
# What   : Supplement Fig. S1. Directed CCF peak-lag matrix, Croc-2 (left) and KHC (right), detrended.
# Inputs : A07_ccf_summary_detrended
# Run from pub_code/:  Rscript figures/SI_FigS1_ccf_peaklag_matrix_detrended.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A07_ccf_summary_detrended")
panel <- function(cave) plot_pair_matrix(tbl, cave, "peak_lag_hr", "Peak lag (h)", signed = TRUE)

g <- panel("Croc-2") | panel("KHC")

save_figure(g, "SI_FigS1_ccf_peaklag_matrix_detrended", width = 12, height = 5.2)
