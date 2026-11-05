# =============================================================================
# A11_teopt_summary_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A11_teopt_summary_detrended.csv
# What   : Delay-optimized TE per pair and direction: u*, surrogate p, edge
#          flag, ETE at u*, net (detrended variant). Slow (several minutes).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS10, SI_FigS11
# Run from pub_code/:  Rscript figures/analysis/A11_teopt_summary_detrended.R
# =============================================================================
# Same computation as SI Table S6; see teopt_results() in lib/directional.R
# for the method and its reasoning.
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R).
pairs <- prepare_pairs(harmonic_detrend)

tbl <- teopt_results(pairs)$summary

write_table(tbl, analysis_path("A11_teopt_summary_detrended"))
