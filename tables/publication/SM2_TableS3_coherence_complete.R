# =============================================================================
# SM2_TableS3_coherence_complete.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SM2_TableS3_coherence_complete.csv
# What   : Supplemental Material File 2, Table S3. Complete coherence/phase summary per pair, as output by R (raw data).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SM2_TableS3_coherence_complete.R
# =============================================================================
source("lib/pub_setup.R")

# Raw variant: series used as recorded (see prepare_pairs and the method
# notes in lib/directional.R).
pairs <- prepare_pairs(identity)

tbl <- coherence_peaks(pairs) %>%
  arrange(Cave, Pair) %>%
  select(Cave, Pair, n_hours_overlap, peak_coherency_sq, delay_at_peak_hr,
         peak_period_hr, phase_at_peak_rad, sig_threshold)

write_table(tbl, pub_path("SM2_TableS3_coherence_complete"))
