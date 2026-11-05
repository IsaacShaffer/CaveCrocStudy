# =============================================================================
# A07_ccf_summary_raw.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A07_ccf_summary_raw.csv
# What   : Cross-correlation peak lag and correlation per within-cave pair (raw variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS11, A14
# Run from pub_code/:  Rscript tables/analysis/A07_ccf_summary_raw.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_ccf_summary("raw"), analysis_path("A07_ccf_summary_raw"))
