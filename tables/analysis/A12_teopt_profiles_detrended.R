# =============================================================================
# A12_teopt_profiles_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A12_teopt_profiles_detrended.csv
# What   : Raw TE versus source delay u (1-24 h), each direction, per pair (detrended).
# Inputs : data/all_cave_temp_data_ext.xlsx (shares cached computation with A11)
# Used by: SI_FigS8, SI_FigS9
# Run from pub_code/:  Rscript tables/analysis/A12_teopt_profiles_detrended.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_teopt_profiles("detrended"), analysis_path("A12_teopt_profiles_detrended"))
