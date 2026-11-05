# =============================================================================
# A12_teopt_profiles_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A12_teopt_profiles_detrended.csv
# What   : Plain TE at every source delay u = 1..24 h, each direction, per
#          pair, with that direction's u* (detrended). Slow (several minutes).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS8, SI_FigS9
# Run from pub_code/:  Rscript figures/analysis/A12_teopt_profiles_detrended.R
# =============================================================================
# SI Table S6 reports only the best delay u*. The whole TE(u) curve shows
# whether u* is a clear peak or one of several near-equal values, and whether
# the curve is still rising at the scan edge. See teopt_results() in
# lib/directional.R.
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R).
pairs <- prepare_pairs(harmonic_detrend)

tbl <- teopt_results(pairs)$profiles

write_table(tbl, analysis_path("A12_teopt_profiles_detrended"))
