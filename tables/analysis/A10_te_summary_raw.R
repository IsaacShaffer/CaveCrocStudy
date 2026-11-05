# =============================================================================
# A10_te_summary_raw.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A10_te_summary_raw.csv
# What   : Effective transfer entropy each way, net and dominant direction per pair (raw variant). Slow (several minutes).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS11, A14
# Run from pub_code/:  Rscript tables/analysis/A10_te_summary_raw.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_te_summary("raw"), analysis_path("A10_te_summary_raw"))
