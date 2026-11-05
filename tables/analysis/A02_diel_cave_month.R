# =============================================================================
# A02_diel_cave_month.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A02_diel_cave_month.csv
# What   : Day and night (18:30-05:30) medians, threshold counts and nightly range by Cave x Month.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: MS_Table2, SM2_TableS1
# Run from pub_code/:  Rscript tables/analysis/A02_diel_cave_month.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_diel_summary(by_logger = FALSE), analysis_path("A02_diel_cave_month"))
