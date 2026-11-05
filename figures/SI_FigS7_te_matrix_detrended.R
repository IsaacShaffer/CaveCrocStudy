# =============================================================================
# SI_FigS7_te_matrix_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS7_te_matrix_detrended.png and .pdf
# What   : Supplement Fig. S7. Directed effective-TE matrix, Croc-2 (left) and KHC (right), detrended; non-significant transfers greyed.
# Inputs : A10_te_summary_detrended
# Run from pub_code/:  Rscript figures/SI_FigS7_te_matrix_detrended.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A10_te_summary_detrended")
panel <- function(cave) plot_pair_matrix_directional(tbl, cave, "ete_a_to_b", "ete_b_to_a", "ETE (bits)",
                                                     pcol_ab = "p_a_to_b", pcol_ba = "p_b_to_a")

g <- panel("Croc-2") | panel("KHC")

save_figure(g, "SI_FigS7_te_matrix_detrended", width = 12, height = 5.2)
