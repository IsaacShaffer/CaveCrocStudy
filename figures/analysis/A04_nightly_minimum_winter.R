# =============================================================================
# A04_nightly_minimum_winter.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A04_nightly_minimum_winter.csv
# What   : Minimum water temperature of each logger-night, winter nights only.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: MS_Fig3
# Run from pub_code/:  Rscript figures/analysis/A04_nightly_minimum_winter.R
# =============================================================================
# Same nightly minima that MS Table 3 summarizes; see winter_nightly_minima()
# in lib/study_data.R for why minima are used.
# =============================================================================
source("lib/pub_setup.R")

tbl <- winter_nightly_minima()

write_table(tbl, analysis_path("A04_nightly_minimum_winter"))
