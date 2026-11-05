# =============================================================================
# SI_FigS10_teopt_matrix_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS10_teopt_matrix_detrended.png and .pdf
# What   : Supplement Fig. S10. Heatmaps of effective TE at the optimal delay
#          u*, from each row logger to each column logger, detrended data.
# Inputs : A11_teopt_summary_detrended
# Run from pub_code/:  Rscript figures/SI_FigS10_teopt_matrix_detrended.R
# =============================================================================
# Same layout as Fig. S7, but each cell uses the delay that maximizes TE for
# that direction, so slower transfers are not missed. Cells whose surrogate
# p_delay >= 0.05 are greyed out.
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A11_teopt_summary_detrended")
panel <- function(cave) {
  plot_pair_matrix_directional(tbl, cave, "ete_a_to_b", "ete_b_to_a",
                               "p_delay_a_to_b", "p_delay_b_to_a", "ETE @ u* (bits)")
}

g <- panel("Croc-2") | panel("KHC")

save_figure(g, "SI_FigS10_teopt_matrix_detrended", width = 12, height = 5.2)
