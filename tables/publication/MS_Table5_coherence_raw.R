# =============================================================================
# MS_Table5_coherence_raw.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table5_coherence_raw.csv
# What   : Manuscript Table 5. Peak squared coherency and phase-derived delay per within-cave pair (raw data).
# Inputs : A08_coherence_summary_raw
# Run from pub_code/:  Rscript tables/publication/MS_Table5_coherence_raw.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A08_coherence_summary_raw") %>%
  arrange(Cave, Pair) %>%
  transmute(Cave          = ms_cave(Cave),
            Pair,
            `Overlap (h)` = n_hours_overlap,
            `Coherency²`  = fmt(peak_coherency_sq, 2),
            `Delay (h)`   = fmt(delay_at_peak_hr, 1))

write_table(tbl, pub_path("MS_Table5_coherence_raw"))
