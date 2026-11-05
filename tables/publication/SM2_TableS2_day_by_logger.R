# =============================================================================
# SM2_TableS2_day_by_logger.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SM2_TableS2_day_by_logger.csv
# What   : Supplemental Material File 2, Table S2. Monthly daytime median and days with an observation >= threshold, by logger.
# Inputs : A03_diel_logger_month
# Run from pub_code/:  Rscript tables/publication/SM2_TableS2_day_by_logger.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A03_diel_logger_month") %>%
  filter(!is.na(n_days)) %>%
  arrange(Cave, Logger, Month) %>%
  transmute(Cave,
            Logger                           = Logger_Name,
            Month,
            `Median day`                     = fmt(median_day, 2),
            `# Days above thermal threshold` = n_days_above,
            `total # days`                   = n_days)

write_table(tbl, pub_path("SM2_TableS2_day_by_logger"))
