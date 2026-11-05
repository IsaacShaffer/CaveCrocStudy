# =============================================================================
# A08_coherence_summary_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A08_coherence_summary_detrended.csv
# What   : Peak squared coherency, period and phase-derived delay per pair (detrended variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_TableS4, SI_FigS6, SI_FigS11, A14
# Run from pub_code/:  Rscript tables/analysis/A08_coherence_summary_detrended.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_coherence_summary("detrended"), analysis_path("A08_coherence_summary_detrended"))
