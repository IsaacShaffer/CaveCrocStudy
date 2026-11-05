# =============================================================================
# A11_teopt_summary_raw.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A11_teopt_summary_raw.csv
# What   : Delay-optimized TE per pair and direction: u*, surrogate p, edge
#          flag, ETE at u*, net (raw variant). Slow (several minutes).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS11
# Run from pub_code/:  Rscript figures/analysis/A11_teopt_summary_raw.R
# =============================================================================
# Same computation as SI Table S6 (detrended there); see teopt_results() in
# lib/directional.R for the method and its reasoning.
# =============================================================================
source("lib/pub_setup.R")

# Raw variant: series used as recorded.
pairs <- prepare_pairs(identity)

tbl <- teopt_results(pairs)$summary

write_table(tbl, analysis_path("A11_teopt_summary_raw"))
