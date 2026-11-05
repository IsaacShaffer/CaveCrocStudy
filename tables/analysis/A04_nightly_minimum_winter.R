# =============================================================================
# A04_nightly_minimum_winter.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A04_nightly_minimum_winter.csv
# What   : Minimum Tw of each logger-night (18:30-05:30), winter nights 2022-11-01 to 2023-02-18.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: MS_Table3, MS_Fig3
# Run from pub_code/:  Rscript tables/analysis/A04_nightly_minimum_winter.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_nightly_minimum_winter(), analysis_path("A04_nightly_minimum_winter"))
