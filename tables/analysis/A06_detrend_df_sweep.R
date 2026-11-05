# =============================================================================
# A06_detrend_df_sweep.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A06_detrend_df_sweep.csv
# What   : Harmonic-spline detrend sweep over spline df: residual SD, variance removed, KPSS pass count.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_TableS2
# Run from pub_code/:  Rscript tables/analysis/A06_detrend_df_sweep.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_detrend_df_sweep(), analysis_path("A06_detrend_df_sweep"))
