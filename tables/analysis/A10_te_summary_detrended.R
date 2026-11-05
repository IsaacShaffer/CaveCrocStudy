# =============================================================================
# A10_te_summary_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A10_te_summary_detrended.csv
# What   : Effective transfer entropy each way, net and dominant direction per pair (detrended variant). Slow (several minutes).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_TableS5, SI_FigS7, SI_FigS11, A14
# Run from pub_code/:  Rscript tables/analysis/A10_te_summary_detrended.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_te_summary("detrended"), analysis_path("A10_te_summary_detrended"))
