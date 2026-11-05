# =============================================================================
# SI_FigS8_teopt_profile_Croc2_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS8_teopt_profile_Croc2_detrended.png and .pdf
# What   : Supplement Fig. S8. Raw TE versus source delay u, both directions, u* marked, Croc-2 (detrended).
# Inputs : A12_teopt_profiles_detrended
# Run from pub_code/:  Rscript figures/SI_FigS8_teopt_profile_Croc2_detrended.R
# =============================================================================
source("lib/pub_setup.R")

cave <- "Croc-2"
prof <- read_analysis("A12_teopt_profiles_detrended")
n_pairs <- n_distinct(prof$Pair[prof$Cave == cave])

g <- plot_te_optimal(prof, cave, "detrended", all_pair_levels)

save_figure(g, "SI_FigS8_teopt_profile_Croc2_detrended", width = 9.5, height = facet_h(ceiling(n_pairs / 2)))
