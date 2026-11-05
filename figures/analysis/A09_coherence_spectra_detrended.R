# =============================================================================
# A09_coherence_spectra_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A09_coherence_spectra_detrended.csv
# What   : Squared coherency, phase and phase-derived delay at every Fourier
#          period from 2 to 168 h, per within-cave pair (detrended variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS4, SI_FigS5
# Run from pub_code/:  Rscript figures/analysis/A09_coherence_spectra_detrended.R
# =============================================================================
# A08 and SI Table S4 keep only the peak of each coherence spectrum. The full spectrum shows
# whether the delay at that peak is stable across neighbouring periods or
# swings wildly, which tells how much to trust a single reported delay. See
# coherence_spectra() in lib/directional.R for how each column is computed.
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R), as in the Supplement.
pairs <- prepare_pairs(harmonic_detrend)

tbl <- coherence_spectra(pairs) %>% arrange(Cave, Pair, period_hr)

write_table(tbl, analysis_path("A09_coherence_spectra_detrended"))
