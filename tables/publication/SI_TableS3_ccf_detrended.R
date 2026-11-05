# =============================================================================
# SI_TableS3_ccf_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS3_ccf_detrended.csv
# What   : Supplement Table S3. Cross-correlation peaks per pair (detrended).
# Inputs : A07_ccf_summary_detrended
# Run from pub_code/:  Rscript tables/publication/SI_TableS3_ccf_detrended.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A07_ccf_summary_detrended") %>%
  arrange(Cave, Pair) %>%
  transmute(Cave, Pair,
            `n (h)`        = n_hours_overlap,
            `Peak lag (h)` = sprintf("%+.2f", peak_lag_hr),
            `Peak r`       = fmt(peak_correlation, 3),
            `Zero-lag r`   = fmt(zero_lag_correlation, 3))

write_table(tbl, pub_path("SI_TableS3_ccf_detrended"))
