# =============================================================================
# A13_lagboot_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A13_lagboot_detrended.csv
# What   : Per-lag pairs-bootstrap 95% interval of the cross-correlation, lags -24..+24 h (detrended variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS2, SI_FigS3, A14
# Run from pub_code/:  Rscript tables/analysis/A13_lagboot_detrended.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_lagboot("detrended"), analysis_path("A13_lagboot_detrended"))
