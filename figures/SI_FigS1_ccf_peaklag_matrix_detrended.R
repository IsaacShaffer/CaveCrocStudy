# =============================================================================
# SI_FigS1_ccf_peaklag_matrix_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS1_ccf_peaklag_matrix_detrended.png and .pdf
# What   : Supplement Fig. S1. Heatmaps of the CCF peak lag (h) for every
#          logger pair, Croc 2 and KHC, detrended data.
# Inputs : A07_ccf_summary_detrended
# Run from pub_code/:  Rscript figures/SI_FigS1_ccf_peaklag_matrix_detrended.R
# =============================================================================
# The time-domain counterpart of the coherence delay matrix (Fig. S6): if both
# methods order the stations the same way, the inferred direction of heat
# movement does not depend on the method. Positive (orange) = row logger leads.
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A07_ccf_summary_detrended")
panel <- function(cave) plot_pair_matrix(tbl, cave, "peak_lag_hr", "Peak lag (h)")

g <- panel("Croc-2") | panel("KHC")

save_figure(g, "SI_FigS1_ccf_peaklag_matrix_detrended", width = 12, height = 5.2)
