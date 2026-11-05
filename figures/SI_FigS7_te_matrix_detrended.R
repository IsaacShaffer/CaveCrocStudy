# =============================================================================
# SI_FigS7_te_matrix_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS7_te_matrix_detrended.png and .pdf
# What   : Supplement Fig. S7. Heatmaps of effective transfer entropy from each
#          row logger to each column logger, Croc 2 and KHC, detrended data.
# Inputs : A10_te_summary_detrended
# Run from pub_code/:  Rscript figures/SI_FigS7_te_matrix_detrended.R
# =============================================================================
# Each direction is its own estimate, so the grid is not symmetric. Cells with
# bootstrap p >= 0.05 are greyed out: only supported transfers are coloured,
# and a row with several coloured cells marks a station that drives others.
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A10_te_summary_detrended")
panel <- function(cave) {
  plot_pair_matrix_directional(tbl, cave, "ete_a_to_b", "ete_b_to_a",
                               "p_a_to_b", "p_b_to_a", "ETE (bits)")
}

g <- panel("Croc-2") | panel("KHC")

save_figure(g, "SI_FigS7_te_matrix_detrended", width = 12, height = 5.2)
