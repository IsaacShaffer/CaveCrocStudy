# =============================================================================
# SM2_TableS1_day_by_cave.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SM2_TableS1_day_by_cave.csv
# What   : Supplemental Material File 2, Table S1. Monthly daytime median and days with an observation >= threshold, by cave.
# Inputs : A02_diel_cave_month
# Run from pub_code/:  Rscript tables/publication/SM2_TableS1_day_by_cave.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A02_diel_cave_month") %>%
  arrange(Cave, Month) %>%
  transmute(Cave, Month,
            `Median day`                     = fmt(median_day, 2),
            `# Days above thermal threshold` = n_days_above,
            `total # days`                   = n_days)

write_table(tbl, pub_path("SM2_TableS1_day_by_cave"))
