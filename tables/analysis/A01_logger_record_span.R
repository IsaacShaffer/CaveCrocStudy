# =============================================================================
# A01_logger_record_span.R
# -----------------------------------------------------------------------------
# Output : output/tables/analysis/A01_logger_record_span.csv
# What   : First and last timestamp recorded by each logger.
# Inputs : data/all_cave_temp_data_ext.xlsx (full deployment, not windowed)
# Used by: MS_Table1, SI_TableS1
# Run from pub_code/:  Rscript tables/analysis/A01_logger_record_span.R
# =============================================================================
source("lib/pub_setup.R")

write_table(build_logger_record_span(), analysis_path("A01_logger_record_span"))
