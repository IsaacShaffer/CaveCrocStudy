# =============================================================================
# A10_te_summary_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A10_te_summary_detrended.csv
# What   : Effective transfer entropy each way, net and dominant direction
#          per pair (detrended variant). Slow (several minutes).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS7, SI_FigS11
# Run from pub_code/:  Rscript figures/analysis/A10_te_summary_detrended.R
# =============================================================================
# Same computation as SI Table S5; see te_summary() in lib/directional.R
# for the method and its reasoning.
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R).
pairs <- prepare_pairs(harmonic_detrend)

tbl <- te_summary(pairs)

write_table(tbl, analysis_path("A10_te_summary_detrended"))
