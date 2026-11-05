# =============================================================================
# A08_coherence_summary_raw.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A08_coherence_summary_raw.csv
# What   : Peak squared coherency, period and phase-derived delay per pair (raw variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: MS_Table5, MS_Fig4, SM2_TableS3, SI_FigS11, A14
# Run from pub_code/:  Rscript tables/analysis/A08_coherence_summary_raw.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_coherence_summary("raw"), analysis_path("A08_coherence_summary_raw"))
