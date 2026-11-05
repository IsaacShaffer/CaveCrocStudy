# =============================================================================
# A13_lagboot_raw.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A13_lagboot_raw.csv
# What   : Per-lag pairs-bootstrap 95% interval of the cross-correlation, lags -24..+24 h (raw variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: A14
# Run from pub_code/:  Rscript tables/analysis/A13_lagboot_raw.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_lagboot("raw"), analysis_path("A13_lagboot_raw"))
