# =============================================================================
# SM2_TableS2_day_by_logger.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SM2_TableS2_day_by_logger.csv
# What   : Supplemental Material File 2, Table S2. Monthly daytime median and
#          days with a reading >= threshold, by logger, Aug 2022 - Feb 2023.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SM2_TableS2_day_by_logger.R
# =============================================================================
# The daytime counterpart of MS Table 4, over the whole analysis window.
# Logger-months without daytime readings have no row.
# =============================================================================
source("lib/pub_setup.R")

tbl <- diel_tagged() %>%
  filter(is_day) %>%
  mutate(Month = format(clock_date, "%Y-%m")) %>%
  filter(Month %in% STUDY_MONTHS) %>%   # drop the partial month before 1 Aug
  group_by(Cave, Logger, Logger_Name, Month) %>%
  summarise(median_day   = round(median(Temperature, na.rm = TRUE), 2),
            n_days       = n_distinct(clock_date),
            n_days_above = n_distinct(clock_date[above_threshold]),
            .groups = "drop") %>%
  arrange(Cave, Logger, Month) %>%
  transmute(Cave,
            Logger                           = Logger_Name,
            Month,
            `Median day`                     = fmt(median_day, 2),
            `# Days above thermal threshold` = n_days_above,
            `total # days`                   = n_days)

write_table(tbl, pub_path("SM2_TableS2_day_by_logger"))
