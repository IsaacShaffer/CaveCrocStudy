# =============================================================================
# SI_TableS3_ccf_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS3_ccf_detrended.csv
# What   : Supplement Table S3. Cross-correlation peaks per pair (detrended).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SI_TableS3_ccf_detrended.R
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R), so the statistics reflect
# station-to-station timing rather than forcing shared by all stations.
pairs <- prepare_pairs(harmonic_detrend)

tbl <- ccf_summary(pairs) %>%
  arrange(Cave, Pair) %>%
  transmute(Cave, Pair,
            `n (h)`        = n_hours_overlap,
            `Peak lag (h)` = sprintf("%+.2f", peak_lag_hr),
            `Peak r`       = fmt(peak_correlation, 3),
            `Zero-lag r`   = fmt(zero_lag_correlation, 3))

write_table(tbl, pub_path("SI_TableS3_ccf_detrended"))
