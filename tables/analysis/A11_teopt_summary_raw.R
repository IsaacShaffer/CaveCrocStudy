# =============================================================================
# A11_teopt_summary_raw.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A11_teopt_summary_raw.csv
# What   : Delay-optimized TE: optimal delay u*, surrogate p, ETE at u*, net per pair (raw variant). Slow (about 10 min).
# Inputs : data/all_cave_temp_data_ext.xlsx (shares cached computation with A12)
# Used by: SI_FigS11, A14
# Run from pub_code/:  Rscript tables/analysis/A11_teopt_summary_raw.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_teopt_summary("raw"), analysis_path("A11_teopt_summary_raw"))
