# =============================================================================
# SI_TableS5_te_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS5_te_detrended.csv
# What   : Supplement Table S5. Effective transfer entropy (bits) each way, net and dominant direction per pair (detrended).
# Inputs : A10_te_summary_detrended
# Run from pub_code/:  Rscript tables/publication/SI_TableS5_te_detrended.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A10_te_summary_detrended") %>%
  arrange(Cave, Pair) %>%
  transmute(Cave, Pair,
            `ETE A->B` = fmt(ete_a_to_b, 3),
            `ETE B->A` = fmt(ete_b_to_a, 3),
            `Net ETE`  = sprintf("%+.3f", net_ete),
            Dominant   = dominant_direction)

write_table(tbl, pub_path("SI_TableS5_te_detrended"))
