# =============================================================================
# A03_diel_logger_month.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A03_diel_logger_month.csv
# What   : Day and night (18:30-05:30) medians, threshold counts and nightly range by Cave x Logger x Month.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: MS_Table4, SM2_TableS2
# Run from pub_code/:  Rscript tables/analysis/A03_diel_logger_month.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_diel_summary(by_logger = TRUE), analysis_path("A03_diel_logger_month"))
