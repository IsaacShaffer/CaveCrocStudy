# =============================================================================
# A07_ccf_summary_raw.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A07_ccf_summary_raw.csv
# What   : Cross-correlation peak lag and peak correlation per within-cave
#          logger pair (raw variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS11
# Run from pub_code/:  Rscript figures/analysis/A07_ccf_summary_raw.R
# =============================================================================
# Same computation as SI Table S3 (detrended there); see ccf_summary() in
# lib/directional.R for the method and its reasoning.
# =============================================================================
source("lib/pub_setup.R")

# Raw variant: series used as recorded.
pairs <- prepare_pairs(identity)

tbl <- ccf_summary(pairs)

write_table(tbl, analysis_path("A07_ccf_summary_raw"))
