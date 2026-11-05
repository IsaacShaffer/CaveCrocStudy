# =============================================================================
# SI_TableS4_coherence_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS4_coherence_detrended.csv
# What   : Supplement Table S4. Cross-spectral coherence peaks per pair (detrended).
# Inputs : A08_coherence_summary_detrended
# Run from pub_code/:  Rscript tables/publication/SI_TableS4_coherence_detrended.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A08_coherence_summary_detrended") %>%
  arrange(Cave, Pair) %>%
  transmute(Cave, Pair,
            `n (h)`             = n_hours_overlap,
            `Peak period (h)`   = fmt(peak_period_hr, 2),
            `Peak coherency^2`  = fmt(peak_coherency_sq, 3),
            `Delay (h)`         = sprintf("%+.2f", delay_at_peak_hr))

write_table(tbl, pub_path("SI_TableS4_coherence_detrended"))
