# =============================================================================
# MS_Table5_coherence_raw.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table5_coherence_raw.csv
# What   : Manuscript Table 5. Peak squared coherency and phase-derived delay per within-cave pair (raw data).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/MS_Table5_coherence_raw.R
# =============================================================================
# The manuscript reports raw-data coherence (Methods: detrended results were
# similar; SI Fig. S11 compares the two). Every peak coherency here exceeds
# its 95% significance threshold, so every delay is interpretable.
# =============================================================================
source("lib/pub_setup.R")

# Raw variant: series used as recorded (see prepare_pairs and the method
# notes in lib/directional.R).
pairs <- prepare_pairs(identity)

tbl <- coherence_peaks(pairs) %>%
  arrange(Cave, Pair) %>%
  transmute(Cave          = ms_cave(Cave),
            Pair,
            `Overlap (h)` = n_hours_overlap,
            `Coherency²`  = fmt(peak_coherency_sq, 2),
            `Delay (h)`   = fmt(delay_at_peak_hr, 1))

write_table(tbl, pub_path("MS_Table5_coherence_raw"))
