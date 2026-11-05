# =============================================================================
# A10_te_summary_raw.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A10_te_summary_raw.csv
# What   : Effective transfer entropy each way, net and dominant direction
#          per pair (raw variant). Slow (several minutes).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS11
# Run from pub_code/:  Rscript figures/analysis/A10_te_summary_raw.R
# =============================================================================
# Same computation as SI Table S5 (detrended there); see te_summary() in
# lib/directional.R for the method and its reasoning.
# =============================================================================
source("lib/pub_setup.R")

# Raw variant: series used as recorded.
pairs <- prepare_pairs(identity)

tbl <- te_summary(pairs)

write_table(tbl, analysis_path("A10_te_summary_raw"))
