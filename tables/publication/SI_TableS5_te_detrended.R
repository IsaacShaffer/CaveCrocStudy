# =============================================================================
# SI_TableS5_te_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS5_te_detrended.csv
# What   : Supplement Table S5. Effective transfer entropy (bits) each way, net and dominant direction per pair (detrended).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SI_TableS5_te_detrended.R
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R), so the statistics reflect
# station-to-station timing rather than forcing shared by all stations.
pairs <- prepare_pairs(harmonic_detrend)

tbl <- te_summary(pairs) %>%   # slow: several minutes
  arrange(Cave, Pair) %>%
  transmute(Cave, Pair,
            `ETE A->B` = fmt(ete_a_to_b, 3),
            `ETE B->A` = fmt(ete_b_to_a, 3),
            `Net ETE`  = sprintf("%+.3f", net_ete),
            Dominant   = dominant_direction)

write_table(tbl, pub_path("SI_TableS5_te_detrended"))
