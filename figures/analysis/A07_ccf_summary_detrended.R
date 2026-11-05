# =============================================================================
# A07_ccf_summary_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A07_ccf_summary_detrended.csv
# What   : Cross-correlation peak lag and peak correlation per within-cave
#          logger pair (detrended variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS1, SI_FigS11
# Run from pub_code/:  Rscript figures/analysis/A07_ccf_summary_detrended.R
# =============================================================================
# Same computation as SI Table S3; see ccf_summary() in lib/directional.R
# for the method and its reasoning.
# =============================================================================
source("lib/pub_setup.R")

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R).
pairs <- prepare_pairs(harmonic_detrend)

tbl <- ccf_summary(pairs)

write_table(tbl, analysis_path("A07_ccf_summary_detrended"))
