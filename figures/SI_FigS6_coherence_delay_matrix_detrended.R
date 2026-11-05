# =============================================================================
# SI_FigS6_coherence_delay_matrix_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS6_coherence_delay_matrix_detrended.png and .pdf
# What   : Supplement Fig. S6. Heatmaps of the phase-derived delay (h) at peak
#          coherency for every logger pair, Croc 2 and KHC, detrended data.
# Inputs : A08_coherence_summary_detrended
# Run from pub_code/:  Rscript figures/SI_FigS6_coherence_delay_matrix_detrended.R
# =============================================================================
# The detrended counterpart of MS Fig. 4. Comparing the two shows whether the
# station ordering survives removal of the seasonal drift and the daily cycle.
# Positive (orange) = row logger leads.
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A08_coherence_summary_detrended")
panel <- function(cave) plot_pair_matrix(tbl, cave, "delay_at_peak_hr", "Delay (h)")

g <- panel("Croc-2") | panel("KHC")

save_figure(g, "SI_FigS6_coherence_delay_matrix_detrended", width = 12, height = 5.2)
