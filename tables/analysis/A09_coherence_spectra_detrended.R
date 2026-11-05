# =============================================================================
# A09_coherence_spectra_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A09_coherence_spectra_detrended.csv
# What   : Squared coherency, phase and phase-derived delay at every frequency, 2-168 h, per pair (detrended).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS4, SI_FigS5
# Run from pub_code/:  Rscript tables/analysis/A09_coherence_spectra_detrended.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_coherence_spectra("detrended"), analysis_path("A09_coherence_spectra_detrended"))
