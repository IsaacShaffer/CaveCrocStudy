# =============================================================================
# SI_TableS4_coherence_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS4_coherence_detrended.csv
# What   : Supplement Table S4. Cross-spectral coherence peaks per pair (detrended).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SI_TableS4_coherence_detrended.R
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R), so the statistics reflect
# station-to-station timing rather than forcing shared by all stations.
pairs <- prepare_pairs(harmonic_detrend)

tbl <- coherence_peaks(pairs) %>%
  arrange(Cave, Pair) %>%
  transmute(Cave, Pair,
            `n (h)`             = n_hours_overlap,
            `Peak period (h)`   = fmt(peak_period_hr, 2),
            `Peak coherency^2`  = fmt(peak_coherency_sq, 3),
            `Delay (h)`         = sprintf("%+.2f", delay_at_peak_hr))

write_table(tbl, pub_path("SI_TableS4_coherence_detrended"))
