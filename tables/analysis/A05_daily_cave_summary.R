# =============================================================================
# A05_daily_cave_summary.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A05_daily_cave_summary.csv
# What   : Daily median, quartiles and range of hourly Tw per cave (all loggers pooled).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: MS_Fig2
# Run from pub_code/:  Rscript tables/analysis/A05_daily_cave_summary.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_daily_cave_summary(), analysis_path("A05_daily_cave_summary"))
