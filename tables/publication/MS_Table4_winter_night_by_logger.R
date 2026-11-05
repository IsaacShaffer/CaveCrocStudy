# =============================================================================
# MS_Table4_winter_night_by_logger.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table4_winter_night_by_logger.csv
# What   : Manuscript Table 4. Winter (Nov-Feb) monthly night median and % nights with an observation >= threshold, by logger.
# Inputs : A03_diel_logger_month
# Run from pub_code/:  Rscript tables/publication/MS_Table4_winter_night_by_logger.R
# =============================================================================
source("lib/pub_setup.R")

winter_months <- format(seq(WINTER[1], WINTER[2], by = "month"), "%Y-%m")

tbl <- read_analysis("A03_diel_logger_month") %>%
  filter(Month %in% winter_months, !is.na(n_nights)) %>%
  arrange(Cave, Logger, Month) %>%
  transmute(Cave   = ms_cave(Cave),
            Logger,
            Month,
            Median = fmt(median_night, 2),
            !!sprintf("Nights > %.2f°C (%%)", THRESHOLD) := fmt(100 * n_nights_above / n_nights, 2))

write_table(tbl, pub_path("MS_Table4_winter_night_by_logger"))
