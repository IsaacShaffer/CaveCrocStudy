# =============================================================================
# A08_coherence_summary_raw.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A08_coherence_summary_raw.csv
# What   : Peak squared coherency, its period, and the phase-derived delay
#          there, per within-cave logger pair (raw variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: MS_Fig4, SI_FigS11
# Run from pub_code/:  Rscript figures/analysis/A08_coherence_summary_raw.R
# =============================================================================
# Same computation as MS Table 5; see coherence_spectra() and
# coherence_peaks() in lib/directional.R for the method and its reasoning.
# =============================================================================
source("lib/pub_setup.R")

# Raw variant: series used as recorded.
pairs <- prepare_pairs(identity)

tbl <- coherence_peaks(pairs)

write_table(tbl, analysis_path("A08_coherence_summary_raw"))
