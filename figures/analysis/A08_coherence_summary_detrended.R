# =============================================================================
# A08_coherence_summary_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A08_coherence_summary_detrended.csv
# What   : Peak squared coherency, its period, and the phase-derived delay
#          there, per within-cave logger pair (detrended variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS6, SI_FigS11
# Run from pub_code/:  Rscript figures/analysis/A08_coherence_summary_detrended.R
# =============================================================================
# Same computation as SI Table S4; see coherence_spectra() and
# coherence_peaks() in lib/directional.R for the method and its reasoning.
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R).
pairs <- prepare_pairs(harmonic_detrend)

tbl <- coherence_peaks(pairs)

write_table(tbl, analysis_path("A08_coherence_summary_detrended"))
