# =============================================================================
# A14_variant_comparison.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A14_variant_comparison.csv
# What   : Raw vs detrended value, delta and sign agreement for each directional statistic.
# Inputs : A07, A08, A10, A11, A13 (raw and detrended)
# Used by: none in the publication (diagnostic; backs the Supplement robustness text)
# Run from pub_code/:  Rscript tables/analysis/A14_variant_comparison.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_variant_comparison(), analysis_path("A14_variant_comparison"))
